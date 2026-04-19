import Foundation

struct WakeSchedule: Identifiable, Hashable {
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

extension WakeSchedule: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, label, isEnabled, startHour, startMinute, endHour, endMinute, repeatDays, requiresACPower
        case hour, minute, holdMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        label = try container.decode(String.self, forKey: .label)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        repeatDays = try container.decode(Set<Weekday>.self, forKey: .repeatDays)
        requiresACPower = try container.decode(Bool.self, forKey: .requiresACPower)

        if let sh = try? container.decode(Int.self, forKey: .startHour) {
            startHour = sh
            startMinute = try container.decode(Int.self, forKey: .startMinute)
            endHour = try container.decode(Int.self, forKey: .endHour)
            endMinute = try container.decode(Int.self, forKey: .endMinute)
        } else {
            let legacyHour = try container.decode(Int.self, forKey: .hour)
            let legacyMinute = try container.decode(Int.self, forKey: .minute)
            let legacyHold = try container.decode(Int.self, forKey: .holdMinutes)

            startHour = legacyHour
            startMinute = legacyMinute
            var endTotal = legacyHour * 60 + legacyMinute + legacyHold
            if endTotal >= 24 * 60 { endTotal = endTotal % (24 * 60) }
            endHour = endTotal / 60
            endMinute = endTotal % 60
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(label, forKey: .label)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(startHour, forKey: .startHour)
        try container.encode(startMinute, forKey: .startMinute)
        try container.encode(endHour, forKey: .endHour)
        try container.encode(endMinute, forKey: .endMinute)
        try container.encode(repeatDays, forKey: .repeatDays)
        try container.encode(requiresACPower, forKey: .requiresACPower)
    }
}
