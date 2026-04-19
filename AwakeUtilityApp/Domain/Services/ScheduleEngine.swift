import Foundation

actor ScheduleEngine {
    private var schedules: [WakeSchedule] = []

    func loadSchedules(from repository: ScheduleRepository) async throws {
        schedules = try await repository.loadAll()
    }

    func reload(_ newSchedules: [WakeSchedule]) {
        schedules = newSchedules
    }

    var allSchedules: [WakeSchedule] {
        schedules
    }

    var enabledSchedules: [WakeSchedule] {
        schedules.filter(\.isEnabled)
    }

    func currentlyEnforcingSchedule(now: Date) -> WakeSchedule? {
        enabledSchedules.first { schedule in
            TriggerCalculator.isInActiveWindow(
                startHour: schedule.startHour,
                startMinute: schedule.startMinute,
                endHour: schedule.endHour,
                endMinute: schedule.endMinute,
                repeatDays: schedule.repeatDays,
                now: now
            )
        }
    }

    func shouldEnforce(now: Date) -> Bool {
        currentlyEnforcingSchedule(now: now) != nil
    }
}
