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

    @Test("No schedules returns nil for currently enforcing")
    func noSchedules() async {
        let engine = ScheduleEngine()
        let now = Date()
        #expect(await engine.currentlyEnforcingSchedule(now: now) == nil)
    }

    @Test("Disabled schedules are ignored")
    func disabledSchedulesIgnored() async {
        let engine = ScheduleEngine()
        let allDays = Set(Weekday.allCases)
        let schedule = WakeSchedule(
            label: "Off", isEnabled: false,
            startHour: 8, startMinute: 0,
            endHour: 17, endMinute: 0,
            repeatDays: allDays,
            requiresACPower: true
        )
        await engine.reload([schedule])
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 10, minute: 0)
        #expect(await engine.currentlyEnforcingSchedule(now: now) == nil)
    }

    @Test("Should enforce returns true when in active window")
    func shouldEnforceInWindow() async {
        let engine = ScheduleEngine()
        let weekday = Calendar.current.component(.weekday, from: makeDate(year: 2026, month: 4, day: 20, hour: 0, minute: 0))
        let day = Weekday(rawValue: weekday)!

        let schedule = WakeSchedule(
            label: "Active", isEnabled: true,
            startHour: 8, startMinute: 0,
            endHour: 17, endMinute: 0,
            repeatDays: [day],
            requiresACPower: true
        )
        await engine.reload([schedule])

        let inWindow = makeDate(year: 2026, month: 4, day: 20, hour: 10, minute: 0)
        #expect(await engine.shouldEnforce(now: inWindow))
    }

    @Test("Should enforce returns false when outside window")
    func shouldNotEnforceOutsideWindow() async {
        let engine = ScheduleEngine()
        let weekday = Calendar.current.component(.weekday, from: makeDate(year: 2026, month: 4, day: 20, hour: 0, minute: 0))
        let day = Weekday(rawValue: weekday)!

        let schedule = WakeSchedule(
            label: "Active", isEnabled: true,
            startHour: 8, startMinute: 0,
            endHour: 17, endMinute: 0,
            repeatDays: [day],
            requiresACPower: true
        )
        await engine.reload([schedule])

        let outside = makeDate(year: 2026, month: 4, day: 20, hour: 18, minute: 0)
        #expect(await !engine.shouldEnforce(now: outside))
    }
}
