import Foundation
import IOKit
import IOKit.pwr_mgt

@MainActor
final class WakeScheduler {
    private var scheduledWakeDate: Date?

    /// Schedule a wake event for the given schedule's start time.
    /// If the time has already passed today, schedules for tomorrow.
    func scheduleWake(for schedule: WakeSchedule) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = schedule.startHour
        components.minute = schedule.startMinute
        components.second = 0

        guard let wakeDate = calendar.date(from: components) else { return }

        if wakeDate <= Date() {
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: wakeDate) {
                scheduleWakeAt(tomorrow)
            }
        } else {
            scheduleWakeAt(wakeDate)
        }
    }

    /// Cancel any previously scheduled wake event.
    func cancelScheduledWake() {
        guard let scheduled = scheduledWakeDate else { return }
        // kIOPMAutoWake is a C macro ("wake") not exported to Swift — use string directly
        IOPMCancelScheduledPowerEvent(scheduled as CFDate, nil, "wake" as CFString)
        scheduledWakeDate = nil
    }

    private func scheduleWakeAt(_ date: Date) {
        // Cancel previous wake event first
        cancelScheduledWake()

        // kIOPMAutoWake is a C macro ("wake") not exported to Swift — use string directly
        let result = IOPMSchedulePowerEvent(date as CFDate, nil, "wake" as CFString)
        if result == kIOReturnSuccess {
            scheduledWakeDate = date
            NSLog("[WakeScheduler] Scheduled wake at \(date)")
        } else {
            NSLog("[WakeScheduler] Failed to schedule wake: \(result)")
        }
    }

    static let shared = WakeScheduler()
}
