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

    // MARK: - nextTargetDate

    @Test("Next target returns today if still in the future")
    func nextTargetReturnsToday() {
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 7, minute: 0)
        let weekday = Calendar.current.component(.weekday, from: now)
        let day = Weekday(rawValue: weekday)!

        let result = TriggerCalculator.nextTargetDate(
            hour: 8, minute: 0, repeatDays: [day], after: now
        )

        #expect(result != nil)
        let calendar = Calendar.current
        let resultHour = calendar.component(.hour, from: result!)
        let resultMinute = calendar.component(.minute, from: result!)
        #expect(resultHour == 8)
        #expect(resultMinute == 0)
    }

    @Test("Next target rolls to next day if today's time has passed")
    func nextTargetRollsToNextDay() {
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 9, minute: 0)
        let weekday = Calendar.current.component(.weekday, from: now)
        let day = Weekday(rawValue: weekday)!

        let result = TriggerCalculator.nextTargetDate(
            hour: 8, minute: 0, repeatDays: [day], after: now
        )

        #expect(result != nil)
        #expect(result! > now)
    }

    @Test("Next target returns nil for empty repeat days")
    func nextTargetReturnsNilForEmptyDays() {
        let now = Date()
        let result = TriggerCalculator.nextTargetDate(
            hour: 8, minute: 0, repeatDays: [], after: now
        )
        #expect(result == nil)
    }

    @Test("Next target works for every day")
    func nextTargetForEveryDay() {
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 7, minute: 0)
        let allDays = Set(Weekday.allCases)

        let result = TriggerCalculator.nextTargetDate(
            hour: 8, minute: 30, repeatDays: allDays, after: now
        )

        #expect(result != nil)
        let calendar = Calendar.current
        #expect(calendar.component(.hour, from: result!) == 8)
        #expect(calendar.component(.minute, from: result!) == 30)
    }

    // MARK: - Window computation

    @Test("Compute window calculates lead start and hold end correctly")
    func computeWindow() {
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 7, minute: 0)
        let weekday = Calendar.current.component(.weekday, from: now)
        let day = Weekday(rawValue: weekday)!

        let schedule = WakeSchedule(
            label: "Test", isEnabled: true,
            hour: 8, minute: 0,
            repeatDays: [day],
            leadMinutes: 15, holdMinutes: 10
        )

        let window = TriggerCalculator.computeWindow(for: schedule, now: now)

        #expect(window != nil)
        let calendar = Calendar.current

        let leadStart = calendar.component(.minute, from: window!.leadStart)
        #expect(leadStart == 45)

        let holdEndHour = calendar.component(.hour, from: window!.holdEnd)
        let holdEndMin = calendar.component(.minute, from: window!.holdEnd)
        #expect(holdEndHour == 8)
        #expect(holdEndMin == 10)
    }

    @Test("Is in lead window returns true when within lead time")
    func isInLeadWindow() {
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 7, minute: 50)
        let weekday = Calendar.current.component(.weekday, from: now)
        let day = Weekday(rawValue: weekday)!

        let schedule = WakeSchedule(
            label: "Test", isEnabled: true,
            hour: 8, minute: 0,
            repeatDays: [day],
            leadMinutes: 15, holdMinutes: 10
        )

        #expect(TriggerCalculator.isInLeadWindow(schedule, now: now))
        #expect(!TriggerCalculator.isInHoldWindow(schedule, now: now))
    }

    @Test("Is in hold window returns true after target time")
    func isInHoldWindow() {
        let now = makeDate(year: 2026, month: 4, day: 20, hour: 8, minute: 5)
        let weekday = Calendar.current.component(.weekday, from: now)
        let day = Weekday(rawValue: weekday)!

        let schedule = WakeSchedule(
            label: "Test", isEnabled: true,
            hour: 8, minute: 0,
            repeatDays: [day],
            leadMinutes: 15, holdMinutes: 10
        )

        #expect(!TriggerCalculator.isInLeadWindow(schedule, now: now))
        #expect(TriggerCalculator.isInHoldWindow(schedule, now: now))
    }

    @Test("Active window covers both lead and hold")
    func isActiveWindow() {
        let weekday = Calendar.current.component(
            .weekday,
            from: makeDate(year: 2026, month: 4, day: 20, hour: 0, minute: 0)
        )
        let day = Weekday(rawValue: weekday)!

        let schedule = WakeSchedule(
            label: "Test", isEnabled: true,
            hour: 8, minute: 0,
            repeatDays: [day],
            leadMinutes: 15, holdMinutes: 10
        )

        let inLead = makeDate(year: 2026, month: 4, day: 20, hour: 7, minute: 50)
        let atTarget = makeDate(year: 2026, month: 4, day: 20, hour: 8, minute: 0)
        let inHold = makeDate(year: 2026, month: 4, day: 20, hour: 8, minute: 5)
        let outside = makeDate(year: 2026, month: 4, day: 20, hour: 6, minute: 0)

        #expect(TriggerCalculator.isActiveWindow(schedule, now: inLead))
        #expect(TriggerCalculator.isActiveWindow(schedule, now: atTarget))
        #expect(TriggerCalculator.isActiveWindow(schedule, now: inHold))
        #expect(!TriggerCalculator.isActiveWindow(schedule, now: outside))
    }
}
