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

    func nextActiveSchedule(now: Date) -> WakeSchedule? {
        let enabled = enabledSchedules
        guard !enabled.isEmpty else { return nil }

        return enabled
            .compactMap { schedule -> (WakeSchedule, Date)? in
                guard let window = TriggerCalculator.computeWindow(for: schedule, now: now) else { return nil }
                return (schedule, window.leadStart)
            }
            .sorted { $0.1 < $1.1 }
            .first?.0
    }

    func nextTriggerDate(now: Date) -> Date? {
        guard let schedule = nextActiveSchedule(now: now) else { return nil }
        return TriggerCalculator.computeWindow(for: schedule, now: now)?.targetTime
    }

    func windowForNextSchedule(now: Date) -> TriggerCalculator.Window? {
        guard let schedule = nextActiveSchedule(now: now) else { return nil }
        return TriggerCalculator.computeWindow(for: schedule, now: now)
    }

    func currentlyEnforcingSchedule(now: Date) -> WakeSchedule? {
        enabledSchedules.first { TriggerCalculator.isActiveWindow($0, now: now) }
    }

    func shouldEnforce(now: Date) -> Bool {
        currentlyEnforcingSchedule(now: now) != nil
    }
}
