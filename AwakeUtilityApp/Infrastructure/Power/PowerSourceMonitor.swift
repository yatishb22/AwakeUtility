import Foundation
import IOKit
import IOKit.ps

@MainActor
final class PowerSourceMonitor: PowerMonitoring {
    private var continuation: AsyncStream<PowerSourceState>.Continuation?
    private var _currentPowerSource: PowerSourceState = .unknown
    private nonisolated(unsafe) var runLoopSource: CFRunLoopSource?

    var currentPowerSource: PowerSourceState {
        get async { _currentPowerSource }
    }

    var powerSourceUpdates: AsyncStream<PowerSourceState> {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                if let source = self?.runLoopSource {
                    CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
                    self?.runLoopSource = nil
                }
            }
        }
    }

    func startMonitoring() {
        let result = Self.readPowerSource()
        NSLog("[PowerSourceMonitor] startMonitoring() — initial: \(result.rawValue)")
        _currentPowerSource = result

        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: @convention(c) (UnsafeMutableRawPointer?) -> Void = { context in
            guard let context else { return }
            let monitor = Unmanaged<PowerSourceMonitor>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async {
                monitor.onPowerSourceChanged()
            }
        }

        if let rlSource = IOPSNotificationCreateRunLoopSource(callback, context) {
            let source = rlSource.takeRetainedValue()
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }
    }

    private func onPowerSourceChanged() {
        let newSource = Self.readPowerSource()
        guard newSource != _currentPowerSource else { return }
        _currentPowerSource = newSource
        continuation?.yield(newSource)
    }

    static func readPowerSource() -> PowerSourceState {
        guard let blobRaw = IOPSCopyPowerSourcesInfo() else {
            return .unknown
        }
        let blob = blobRaw.takeRetainedValue()
        guard let sourceListRaw = IOPSCopyPowerSourcesList(blob) else {
            return .unknown
        }
        let sourceList = sourceListRaw.takeRetainedValue() as! [CFTypeRef]

        for source in sourceList {
            guard let descRaw = IOPSGetPowerSourceDescription(blob, source) else {
                continue
            }
            let desc = descRaw.takeUnretainedValue() as! [String: Any]

            if let state = desc[kIOPSPowerSourceStateKey as String] as? String {
                if state == kIOPSACPowerValue as String {
                    return .ac
                } else if state == kIOPSBatteryPowerValue as String {
                    return .battery
                }
            }
        }
        return .unknown
    }

    static let shared = PowerSourceMonitor()
}
