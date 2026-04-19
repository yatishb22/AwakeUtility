import SwiftUI

@Observable
@MainActor
final class AppCoordinator {

    var runtimeState = RuntimeState()
    var schedules: [WakeSchedule] = []
    var showingScheduleEditor = false
    var editingSchedule: WakeSchedule?

    private let scheduleEngine = ScheduleEngine()
    let scheduleRepository = JSONScheduleRepository()
    let powerMonitor = PowerSourceMonitor.shared
    let assertionManager = PowerAssertionManager()
    let wakeScheduler = WakeScheduler.shared
    private var enforcementTimer: Task<Void, Never>?
    let logger = LocalLogger()

    private static let schedulesFileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("AwakeUtility", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("schedules.json")
    }()

    init() {
        schedules = Self.loadSchedulesSync()
        runtimeState.powerSource = PowerSourceMonitor.readPowerSource()
    }

    var iconName: String {
        switch runtimeState.enforcementState {
        case .active:
            return "bolt.circle.fill"
        case .waitingForAC:
            return "bolt.slash.circle"
        case .failed:
            return "exclamationmark.circle"
        case .idle:
            return "moon.circle"
        }
    }

    func start() async {
        NSLog("[AwakeUtility] start() called")
        let initialPower = PowerSourceMonitor.readPowerSource()
        runtimeState.powerSource = initialPower
        powerMonitor.startMonitoring()

        // Subscribe to power source changes
        Task { @MainActor in
            for await state in powerMonitor.powerSourceUpdates {
                NSLog("[AwakeUtility] Power source changed: \(state.rawValue)")
                runtimeState.powerSource = state
                await updateEnforcementState()
            }
        }

        // Start 30-second enforcement check timer
        enforcementTimer = Task { @MainActor in
            while !Task.isCancelled {
                await updateEnforcementState()
                try? await Task.sleep(for: .seconds(30))
            }
        }

        await updateEnforcementState()
        NSLog("[AwakeUtility] start() done. enforcement=\(runtimeState.enforcementState.displayName) power=\(runtimeState.powerSource.rawValue)")
    }

    func loadSchedules() async {
        do {
            schedules = try await scheduleRepository.loadAll()
            await scheduleEngine.reload(schedules)
        } catch {
            logger.log(LogEvent(type: .error, message: "Failed to load schedules: \(error.localizedDescription)"))
        }
    }

    func saveSchedule(_ schedule: WakeSchedule) async {
        do {
            try await scheduleRepository.save(schedule)
            schedules = try await scheduleRepository.loadAll()
            await scheduleEngine.reload(schedules)
        } catch {
            logger.log(LogEvent(type: .error, message: "Failed to save schedule: \(error.localizedDescription)"))
        }
    }

    func deleteSchedule(_ id: UUID) async {
        do {
            try await scheduleRepository.delete(id)
            schedules = try await scheduleRepository.loadAll()
            await scheduleEngine.reload(schedules)
        } catch {
            logger.log(LogEvent(type: .error, message: "Failed to delete schedule: \(error.localizedDescription)"))
        }
    }

    func createNewSchedule() {
        editingSchedule = WakeSchedule()
        showingScheduleEditor = true
    }

    func openScheduleEditor(for schedule: WakeSchedule) {
        editingSchedule = schedule
        showingScheduleEditor = true
    }

    func dismissEditor() {
        showingScheduleEditor = false
        editingSchedule = nil
    }

    func refreshRuntimeState() async {
        await updateEnforcementState()
    }

    private func updateEnforcementState() async {
        let schedule = await scheduleEngine.currentlyEnforcingSchedule(now: Date())

        guard let schedule = schedule else {
            // Outside any window
            runtimeState.enforcementState = .idle
            if await assertionManager.isActive {
                try? await assertionManager.releaseAssertion()
            }
            wakeScheduler.cancelScheduledWake()
            return
        }

        // In active window
        if runtimeState.powerSource == .ac {
            // On AC — enforce
            runtimeState.enforcementState = .active
            if !(await assertionManager.isActive) {
                try? await assertionManager.acquireAssertion()
            }
            wakeScheduler.scheduleWake(for: schedule)
        } else {
            // On battery — wait
            runtimeState.enforcementState = .waitingForAC
            if await assertionManager.isActive {
                try? await assertionManager.releaseAssertion()
            }
            // Keep wake scheduled in case AC reconnects
        }
    }

    private static func loadSchedulesSync() -> [WakeSchedule] {
        guard FileManager.default.fileExists(atPath: schedulesFileURL.path),
              let data = try? Data(contentsOf: schedulesFileURL),
              let decoded = try? JSONDecoder().decode([WakeSchedule].self, from: data) else {
            return []
        }
        return decoded
    }
}
