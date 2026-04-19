import Foundation
import IOKit
import IOKit.pwr_mgt

@MainActor
final class WakeScheduler {
    private var scheduledWakeDate: Date?

    /// Schedule the NEXT wake event across all enabled schedules.
    /// Finds the earliest upcoming start time and schedules it.
    func scheduleNextWake(for schedules: [WakeSchedule]) {
        let enabled = schedules.filter(\.isEnabled)
        guard !enabled.isEmpty else {
            cancelScheduledWake()
            return
        }

        let calendar = Calendar.current
        let now = Date()
        var nearestWakeDate: Date?

        for schedule in enabled {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = schedule.startHour
            components.minute = schedule.startMinute
            components.second = 0

            guard var wakeDate = calendar.date(from: components) else { continue }

            if wakeDate <= now {
                guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: wakeDate) else { continue }
                wakeDate = tomorrow
            }

            if nearestWakeDate == nil || wakeDate < nearestWakeDate! {
                nearestWakeDate = wakeDate
            }
        }

        if let target = nearestWakeDate {
            scheduleWakeAt(target)
        } else {
            cancelScheduledWake()
        }
    }

    func cancelScheduledWake() {
        guard let scheduled = scheduledWakeDate else { return }
        IOPMCancelScheduledPowerEvent(scheduled as CFDate, nil, "wake" as CFString)
        scheduledWakeDate = nil
        NSLog("[WakeScheduler] Cancelled wake event")
    }

    private func scheduleWakeAt(_ date: Date) {
        cancelScheduledWake()

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
