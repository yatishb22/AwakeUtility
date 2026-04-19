import Testing
import Foundation

@testable import AwakeUtility

struct ScheduleEngineTests {

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

    @Test("No schedules returns nil for next active")
    func noSchedules() async {
        let engine = ScheduleEngine()
        let now = Date()
        #expect(await engine.nextActiveSchedule(now: now) == nil)
    }

    @Test("Disabled schedules are ignored")
    func disabledSchedulesIgnored() async {
        let engine = ScheduleEngine()
        let schedule = WakeSchedule(label: "Off", isEnabled: false, hour: 8, minute: 0)
        await engine.reload([schedule])
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 7, minute: 0)
        #expect(await engine.nextActiveSchedule(now: now) == nil)
    }

    @Test("Enabled schedule returns the correct next schedule")
    func enabledScheduleFound() async {
        let engine = ScheduleEngine()
        let allDays = Set(Weekday.allCases)
        let schedule = WakeSchedule(label: "Morning", isEnabled: true, hour: 8, minute: 0, repeatDays: allDays)
        await engine.reload([schedule])

        let now = makeDate(year: 2026, month: 4, day: 20, hour: 7, minute: 0)
        let result = await engine.nextActiveSchedule(now: now)
        #expect(result?.label == "Morning")
    }

    @Test("Should enforce returns true when in active window")
    func shouldEnforceInWindow() async {
        let engine = ScheduleEngine()
        let weekday = Calendar.current.component(.weekday, from: makeDate(year: 2026, month: 4, day: 20, hour: 0, minute: 0))
        let day = Weekday(rawValue: weekday)!

        let schedule = WakeSchedule(
            label: "Active", isEnabled: true,
            hour: 8, minute: 0,
            repeatDays: [day],
            leadMinutes: 15, holdMinutes: 10
        )
        await engine.reload([schedule])

        let inWindow = makeDate(year: 2026, month: 4, day: 20, hour: 7, minute: 50)
        #expect(await engine.shouldEnforce(now: inWindow))
    }

    @Test("Should enforce returns false when outside window")
    func shouldNotEnforceOutsideWindow() async {
        let engine = ScheduleEngine()
        let weekday = Calendar.current.component(.weekday, from: makeDate(year: 2026, month: 4, day: 20, hour: 0, minute: 0))
        let day = Weekday(rawValue: weekday)!

        let schedule = WakeSchedule(
            label: "Active", isEnabled: true,
            hour: 8, minute: 0,
            repeatDays: [day],
            leadMinutes: 15, holdMinutes: 10
        )
        await engine.reload([schedule])

        let outside = makeDate(year: 2026, month: 4, day: 20, hour: 6, minute: 0)
        #expect(!await engine.shouldEnforce(now: outside))
    }

    @Test("Overlapping schedules picks earliest lead start")
    func overlappingSchedulesPicksEarliest() async {
        let engine = ScheduleEngine()
        let allDays = Set(Weekday.allCases)

        let early = WakeSchedule(label: "Early", isEnabled: true, hour: 7, minute: 30, repeatDays: allDays, leadMinutes: 15, holdMinutes: 5)
        let late = WakeSchedule(label: "Late", isEnabled: true, hour: 8, minute: 0, repeatDays: allDays, leadMinutes: 15, holdMinutes: 5)
        await engine.reload([late, early])

        let now = makeDate(year: 2026, month: 4, day: 20, hour: 6, minute: 0)
        let result = await engine.nextActiveSchedule(now: now)
        #expect(result?.label == "Early")
    }
}
