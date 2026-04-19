import Foundation

enum Weekday: Int, Codable, CaseIterable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var shortName: String {
        let formatter = DateFormatter()
        let symbol = formatter.shortWeekdaySymbols[rawValue - 1]
        return symbol
    }

    var fullName: String {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[rawValue - 1]
    }

    var calendarValue: Int { rawValue }
}
