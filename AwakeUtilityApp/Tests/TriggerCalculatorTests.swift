import Testing
import Foundation

@testable import AwakeUtility

struct TriggerCalculatorTests {

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = TimeZone.current
        return Calendar.current.date(from: components)!
    }

    @Test("Is in active window returns true during same-day window")
    func isInActiveWindowSameDay() {
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 10, minute: 0)
        let weekday = Calendar.current.component(.weekday, from: now)
        let day = Weekday(rawValue: weekday)!

        #expect(TriggerCalculator.isInActiveWindow(
            startHour: 8, startMinute: 0,
            endHour: 17, endMinute: 0,
            repeatDays: [day],
            now: now
        ))
    }

    @Test("Is in active window returns true during overnight window")
    func isInActiveWindowOvernight() {
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 2, minute: 0)
        let weekday = Calendar.current.component(.weekday, from: now)
        let day = Weekday(rawValue: weekday)!

        #expect(TriggerCalculator.isInActiveWindow(
            startHour: 22, startMinute: 0,
            endHour: 6, endMinute: 0,
            repeatDays: [day],
            now: now
        ))
    }

    @Test("Is in active window returns false outside window")
    func isNotInActiveWindow() {
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 18, minute: 0)
        let weekday = Calendar.current.component(.weekday, from: now)
        let day = Weekday(rawValue: weekday)!

        #expect(!TriggerCalculator.isInActiveWindow(
            startHour: 8, startMinute: 0,
            endHour: 17, endMinute: 0,
            repeatDays: [day],
            now: now
        ))
    }

    @Test("Start equals end means 24-hour window")
    func startEqualsEndIsAllDay() {
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 23, minute: 59)
        let weekday = Calendar.current.component(.weekday, from: now)
        let day = Weekday(rawValue: weekday)!

        #expect(TriggerCalculator.isInActiveWindow(
            startHour: 8, startMinute: 0,
            endHour: 8, endMinute: 0,
            repeatDays: [day],
            now: now
        ))
    }

    @Test("Empty repeat days returns false")
    func emptyRepeatDays() {
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 10, minute: 0)
        #expect(!TriggerCalculator.isInActiveWindow(
            startHour: 8, startMinute: 0,
            endHour: 17, endMinute: 0,
            repeatDays: [],
            now: now
        ))
    }
}
