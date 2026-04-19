import Foundation

struct TriggerCalculator {

    static func isInActiveWindow(
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        repeatDays: Set<Weekday>,
        now: Date
    ) -> Bool {
        guard !repeatDays.isEmpty else { return false }

        let calendar = Calendar.current
        let weekdayValue = calendar.component(.weekday, from: now)
        guard repeatDays.contains(where: { $0.rawValue == weekdayValue }) else {
            return false
        }

        let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        if startMinutes < endMinutes {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        } else if startMinutes > endMinutes {
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        } else {
            return true
        }
    }
}
