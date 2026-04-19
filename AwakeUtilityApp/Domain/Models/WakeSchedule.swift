import Foundation

struct WakeSchedule: Identifiable, Codable, Hashable {
    let id: UUID
    var label: String
    var isEnabled: Bool
    var hour: Int
    var minute: Int
    var repeatDays: Set<Weekday>
    var leadMinutes: Int
    var holdMinutes: Int
    var requiresACPower: Bool
    var advancedWakeEnabled: Bool

    init(
        id: UUID = UUID(),
        label: String = "New Schedule",
        isEnabled: Bool = true,
        hour: Int = 8,
        minute: Int = 0,
        repeatDays: Set<Weekday> = Set(Weekday.allCases),
        leadMinutes: Int = 15,
        holdMinutes: Int = 15,
        requiresACPower: Bool = true,
        advancedWakeEnabled: Bool = false
    ) {
        self.id = id
        self.label = label
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
        self.repeatDays = repeatDays
        self.leadMinutes = leadMinutes
        self.holdMinutes = holdMinutes
        self.requiresACPower = requiresACPower
        self.advancedWakeEnabled = advancedWakeEnabled
    }

    var targetTime: String {
        String(format: "%02d:%02d", hour, minute)
    }
}
