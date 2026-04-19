import Foundation

struct WakeSchedule: Identifiable, Codable, Hashable {
    let id: UUID
    var label: String
    var isEnabled: Bool
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var repeatDays: Set<Weekday>
    var requiresACPower: Bool

    init(
        id: UUID = UUID(),
        label: String = "New Schedule",
        isEnabled: Bool = true,
        startHour: Int = 8,
        startMinute: Int = 0,
        endHour: Int = 17,
        endMinute: Int = 0,
        repeatDays: Set<Weekday> = Set(Weekday.allCases),
        requiresACPower: Bool = true
    ) {
        self.id = id
        self.label = label
        self.isEnabled = isEnabled
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.repeatDays = repeatDays
        self.requiresACPower = requiresACPower
    }

    var windowDescription: String {
        let start = String(format: "%02d:%02d", startHour, startMinute)
        let end = String(format: "%02d:%02d", endHour, endMinute)
        return "\(start) - \(end)"
    }
}
