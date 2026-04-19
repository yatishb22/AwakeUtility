import Foundation

struct TriggerCalculator {

    struct Window {
        let leadStart: Date
        let targetTime: Date
        let holdEnd: Date
    }

    static func nextTargetDate(
        hour: Int,
        minute: Int,
        repeatDays: Set<Weekday>,
        after now: Date
    ) -> Date? {
        guard !repeatDays.isEmpty else { return nil }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let targetToday = calendar.date(from: components) else { return nil }

        if isDayMatching(repeatDays, date: now), targetToday > now {
            return targetToday
        }

        for dayOffset in 1...7 {
            guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            if isDayMatching(repeatDays, date: futureDate) {
                var futureComponents = calendar.dateComponents([.year, .month, .day], from: futureDate)
                futureComponents.hour = hour
                futureComponents.minute = minute
                futureComponents.second = 0
                if let result = calendar.date(from: futureComponents) {
                    return result
                }
            }
        }

        return nil
    }

    static func computeWindow(
        for schedule: WakeSchedule,
        now: Date
    ) -> Window? {
        guard let target = nextTargetDate(
            hour: schedule.hour,
            minute: schedule.minute,
            repeatDays: schedule.repeatDays,
            after: now
        ) else { return nil }

        let calendar = Calendar.current
        let leadStart = calendar.date(
            byAdding: .minute,
            value: -schedule.leadMinutes,
            to: target
        )!
        let holdEnd = calendar.date(
            byAdding: .minute,
            value: schedule.holdMinutes,
            to: target
        )!

        return Window(leadStart: leadStart, targetTime: target, holdEnd: holdEnd)
    }

    static func isInLeadWindow(_ schedule: WakeSchedule, now: Date) -> Bool {
        guard let window = computeWindow(for: schedule, now: now) else { return false }
        return now >= window.leadStart && now < window.targetTime
    }

    static func isInHoldWindow(_ schedule: WakeSchedule, now: Date) -> Bool {
        guard let window = computeWindow(for: schedule, now: now) else { return false }
        return now >= window.targetTime && now < window.holdEnd
    }

    static func isActiveWindow(_ schedule: WakeSchedule, now: Date) -> Bool {
        isInLeadWindow(schedule, now: now) || isInHoldWindow(schedule, now: now)
    }

    private static func isDayMatching(_ days: Set<Weekday>, date: Date) -> Bool {
        let calendar = Calendar.current
        let weekdayValue = calendar.component(.weekday, from: date)
        return days.contains { $0.rawValue == weekdayValue }
    }
}
