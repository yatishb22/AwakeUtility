# Duration Window Wake Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace single-point-in-time schedule with a duration window (8 AM - 5 PM) that keeps Mac awake and wakes from sleep when on AC power.

**Architecture:** Real IOKit power assertions prevent sleep. IOPMSchedulePowerEvent schedules wake events. AppCoordinator orchestrates via timer + power source monitoring.

**Tech Stack:** SwiftUI, IOKit power management, AsyncStream, Swift Testing framework.

---

## Task 1: Update WakeSchedule Model

**Files:**
- Modify: `AwakeUtilityApp/Domain/Models/WakeSchedule.swift:3-42`

- [ ] **Step 1: Replace time fields with start/end window**

```swift
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
```

- [ ] **Step 2: Run build to verify compilation errors in dependent files**

Run: `xcodebuild -project AwakeUtility.xcodeproj -scheme AwakeUtility -configuration Debug build`
Expected: FAIL with compilation errors in files that reference removed properties

- [ ] **Step 3: Commit**

```bash
git add AwakeUtilityApp/Domain/Models/WakeSchedule.swift
git commit -m "refactor: update WakeSchedule model for duration window

Replace hour/minute/leadMinutes/holdMinutes/advancedWakeEnabled
with startHour/startMinute/endHour/endMinute for time window."
```

---

## Task 2: Simplify EnforcementState

**Files:**
- Modify: `AwakeUtilityApp/Domain/Models/EnforcementState.swift:3-26`

- [ ] **Step 1: Replace enum cases**

```swift
enum EnforcementState: String, Codable {
    case idle
    case active
    case waitingForAC
    case failed

    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .active: return "Active"
        case .waitingForAC: return "Waiting for AC"
        case .failed: return "Failed"
        }
    }

    var isActive: Bool {
        self == .active
    }
}
```

- [ ] **Step 2: Run build to verify compilation errors in dependent files**

Run: `xcodebuild -project AwakeUtility.xcodeproj -scheme AwakeUtility -configuration Debug build`
Expected: FAIL with compilation errors in files that reference removed cases

- [ ] **Step 3: Commit**

```bash
git add AwakeUtilityApp/Domain/Models/EnforcementState.swift
git commit -m "refactor: simplify EnforcementState to 4 cases

Remove scheduled/enforcing/holdWindow. Keep idle/active/waitingForAC/failed."
```

---

## Task 3: Rewrite TriggerCalculator for Range Check

**Files:**
- Modify: `AwakeUtilityApp/Domain/Services/TriggerCalculator.swift:1-93`
- Test: `AwakeUtilityApp/Tests/TriggerCalculatorTests.swift:1-167`

- [ ] **Step 1: Write failing test for window range check**

```swift
// In TriggerCalculatorTests.swift, add at end of file:

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
    // 10 PM to 6 AM next day
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project AwakeUtility.xcodeproj -scheme AwakeUtility -destination 'platform=macOS'`
Expected: FAIL with "isInActiveWindow not defined"

- [ ] **Step 3: Implement TriggerCalculator rewrite**

Replace entire contents of `TriggerCalculator.swift` with:

```swift
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

        // Same day window (e.g. 8:00 - 17:00)
        if startMinutes < endMinutes {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        }
        // Overnight window (e.g. 22:00 - 06:00)
        else if startMinutes > endMinutes {
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        }
        // 24-hour window (start == end)
        else {
            return true
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project AwakeUtility.xcodeproj -scheme AwakeUtility -destination 'platform=macOS'`
Expected: PASS for all new tests

- [ ] **Step 5: Delete obsolete tests**

Remove from `TriggerCalculatorTests.swift`:
- All tests in the `// MARK: - nextTargetDate` section
- All tests in the `// MARK: - Window computation` section
- All tests in `// MARK: - Window computation` section
- Keep only the file header and the `makeDate` helper

- [ ] **Step 6: Run tests to verify cleaned test file still passes**

Run: `xcodebuild test -project AwakeUtility.xcodeproj -scheme AwakeUtility -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add AwakeUtilityApp/Domain/Services/TriggerCalculator.swift
git add AwakeUtilityApp/Tests/TriggerCalculatorTests.swift
git commit -m "refactor: rewrite TriggerCalculator for duration window

Replace lead/hold window logic with simple range check.
Support overnight windows (end < start).
Add tests for same-day, overnight, and 24-hour windows."
```

---

## Task 4: Update ScheduleEngine

**Files:**
- Modify: `AwakeUtilityApp/Domain/Services/ScheduleEngine.swift:1-53`
- Test: `AwakeUtilityApp/Tests/ScheduleEngineTests.swift:1-98`

- [ ] **Step 1: Write failing test for shouldEnforce with new model**

```swift
// In ScheduleEngineTests.swift, replace all existing tests with:

@Test("Should enforce returns true when in active window and AC required")
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
    #expect(!await engine.shouldEnforce(now: outside))
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
    #expect(!await engine.shouldEnforce(now: now))
}

@Test("No schedules returns nil for currently enforcing")
func noSchedules() async {
    let engine = ScheduleEngine()
    let now = Date()
    #expect(await engine.currentlyEnforcingSchedule(now: now) == nil)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project AwakeUtility.xcodeproj -scheme AwakeUtility -destination 'platform=macOS'`
Expected: FAIL with method not found or type mismatch

- [ ] **Step 3: Implement ScheduleEngine rewrite**

Replace entire contents of `ScheduleEngine.swift` with:

```swift
import Foundation

actor ScheduleEngine {
    private var schedules: [WakeSchedule] = []

    func loadSchedules(from repository: ScheduleRepository) async throws {
        schedules = try await repository.loadAll()
    }

    func reload(_ newSchedules: [WakeSchedule]) {
        schedules = newSchedules
    }

    var allSchedules: [WakeSchedule] {
        schedules
    }

    var enabledSchedules: [WakeSchedule] {
        schedules.filter(\.isEnabled)
    }

    func currentlyEnforcingSchedule(now: Date) -> WakeSchedule? {
        enabledSchedules.first { schedule in
            TriggerCalculator.isInActiveWindow(
                startHour: schedule.startHour,
                startMinute: schedule.startMinute,
                endHour: schedule.endHour,
                endMinute: schedule.endMinute,
                repeatDays: schedule.repeatDays,
                now: now
            )
        }
    }

    func shouldEnforce(now: Date) -> Bool {
        currentlyEnforcingSchedule(now: now) != nil
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project AwakeUtility.xcodeproj -scheme AwakeUtility -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add AwakeUtilityApp/Domain/Services/ScheduleEngine.swift
git add AwakeUtilityApp/Tests/ScheduleEngineTests.swift
git commit -m "refactor: update ScheduleEngine for duration window

Remove lead/hold window methods. Use TriggerCalculator.isInActiveWindow.
Add tests for shouldEnforce with new model."
```

---

## Task 5: Implement Real Power Assertions

**Files:**
- Modify: `AwakeUtilityApp/Infrastructure/Power/PowerAssertionManager.swift:1-39`

- [ ] **Step 1: Write failing test for assertion lifecycle**

Create `AwakeUtilityApp/Tests/PowerAssertionManagerTests.swift`:

```swift
import Testing
import Foundation
@testable import AwakeUtility

struct PowerAssertionManagerTests {

    @Test("Acquire assertion sets active state")
    func acquireSetsActive() async {
        let manager = PowerAssertionManager()
        #expect(!await manager.isActive)

        try? await manager.acquireAssertion()
        #expect(await manager.isActive)
    }

    @Test("Release assertion clears active state")
    func releaseClearsActive() async {
        let manager = PowerAssertionManager()
        try? await manager.acquireAssertion()
        #expect(await manager.isActive)

        try? await manager.releaseAssertion()
        #expect(!await manager.isActive)
    }

    @Test("Acquire twice throws error")
    func acquireTwiceThrows() async {
        let manager = PowerAssertionManager()
        try? await manager.acquireAssertion()

        let result = await manager.acquireAssertion()
        #expect(result != nil)
    }

    @Test("Release without acquire throws error")
    func releaseWithoutAcquireThrows() async {
        let manager = PowerAssertionManager()

        let result = await manager.releaseAssertion()
        #expect(result != nil)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail (current implementation is stub)**

Run: `xcodebuild test -project AwakeUtility.xcodeproj -scheme AwakeUtility -destination 'platform=macOS'`
Expected: Current tests PASS but implementation is a stub

- [ ] **Step 3: Implement real IOKit power assertions**

Replace entire contents of `PowerAssertionManager.swift` with:

```swift
import Foundation
import IOKit
import IOKit.pwrMgmt

actor PowerAssertionManager: AwakeEnforcing {
    private var _isActive: Bool = false
    private var assertionID: IOPMAssertionID = IOPMAssertionID(0)

    var isActive: Bool { _isActive }

    func acquireAssertion() async throws {
        guard !_isActive else {
            throw AssertionError.alreadyActive
        }

        let reason = "AwakeUtility keeping Mac awake during scheduled window" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )

        guard result == kIOReturnSuccess else {
            throw AssertionError.assertionFailed
        }

        _isActive = true
    }

    func releaseAssertion() async throws {
        guard _isActive else {
            throw AssertionError.notActive
        }

        let result = IOPMAssertionRelease(assertionID)
        guard result == kIOReturnSuccess else {
            throw AssertionError.releaseFailed
        }

        assertionID = IOPMAssertionID(0)
        _isActive = false
    }

    enum AssertionError: LocalizedError {
        case alreadyActive
        case notActive
        case assertionFailed
        case releaseFailed

        var errorDescription: String? {
            switch self {
            case .alreadyActive: return "Assertion already active"
            case .notActive: return "No active assertion to release"
            case .assertionFailed: return "Failed to create power assertion"
            case .releaseFailed: return "Failed to release power assertion"
            }
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project AwakeUtility.xcodeproj -scheme AwakeUtility -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add AwakeUtilityApp/Infrastructure/Power/PowerAssertionManager.swift
git add AwakeUtilityApp/Tests/PowerAssertionManagerTests.swift
git commit -m "feat: implement real IOKit power assertions

Replace stub with IOPMAssertionCreateWithName to prevent system sleep.
Add tests for assertion lifecycle and error handling."
```

---

## Task 6: Create WakeScheduler

**Files:**
- Create: `AwakeUtilityApp/Infrastructure/Power/WakeScheduler.swift`

- [ ] **Step 1: Write WakeScheduler protocol and implementation**

```swift
import Foundation
import IOKit
import IOKit.pwrMgmt

@MainActor
final class WakeScheduler {
    private var scheduledWakeDate: Date?

    func scheduleWake(for schedule: WakeSchedule) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        components.hour = schedule.startHour
        components.minute = schedule.startMinute
        components.second = 0

        guard let wakeDate = calendar.date(from: components) else { return }

        // If wake time has passed today, schedule for tomorrow
        if wakeDate <= Date() {
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: wakeDate) {
                scheduleWakeAt(tomorrow)
            }
        } else {
            scheduleWakeAt(wakeDate)
        }
    }

    func cancelScheduledWake() {
        guard let scheduled = scheduledWakeDate else { return }
        IOPMCancelScheduledPowerEvent(scheduled)
        scheduledWakeDate = nil
    }

    private func scheduleWakeAt(_ date: Date) {
        IOPMSchedulePowerEvent(date, kIOPMAssertionTypeWake)
        scheduledWakeDate = date
    }

    static let shared = WakeScheduler()
}
```

- [ ] **Step 2: Run build to verify no errors**

Run: `xcodebuild -project AwakeUtility.xcodeproj -scheme AwakeUtility -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Add WakeScheduler.swift to Xcode project**

```bash
# Open Xcode project and add the new file to the target
# Or use the project.pbxproj directly — for now, build will fail until added
```

- [ ] **Step 4: Commit**

```bash
git add AwakeUtilityApp/Infrastructure/Power/WakeScheduler.swift
git commit -m "feat: add WakeScheduler for power-on events

Schedule wake events via IOPMSchedulePowerEvent.
Handles same-day and next-day scheduling."
```

---

## Task 7: Update AppCoordinator Orchestration

**Files:**
- Modify: `AwakeUtilityApp/App/AppCoordinator.swift:1-124`

- [ ] **Step 1: Add WakeScheduler import and instance**

Add at top of file:
```swift
import IOKit.pwrMgmt
```

Add property after `assertionManager`:
```swift
let wakeScheduler = WakeScheduler.shared
```

Add timer property:
```swift
private var enforcementTimer: Task<Void, Never>?
```

- [ ] **Step 2: Update start() method for orchestration loop**

Replace the `start()` method with:

```swift
func start() async {
    // Initial power source read
    let initialPower = PowerSourceMonitor.readPowerSource()
    runtimeState.powerSource = initialPower
    powerMonitor.startMonitoring()

    // Subscribe to power source changes
    Task { @MainActor in
        for await state in powerMonitor.powerSourceUpdates {
            runtimeState.powerSource = state
            await updateEnforcementState()
        }
    }

    // Start 30-second enforcement check timer
    enforcementTimer = Task { @MainActor in
        while !Task.isCancelled {
            await updateEnforcementState()
            try? await Task.sleep(for: .seconds(30))
        }
    }

    await updateEnforcementState()
}

private func updateEnforcementState() async {
    let schedule = await scheduleEngine.currentlyEnforcingSchedule(now: Date())

    guard let schedule = schedule else {
        // Outside any window
        runtimeState.enforcementState = .idle
        if await assertionManager.isActive {
            try? await assertionManager.releaseAssertion()
        }
        wakeScheduler.cancelScheduledWake()
        return
    }

    // In active window
    if runtimeState.powerSource == .ac {
        // On AC — enforce
        runtimeState.enforcementState = .active
        if !(await assertionManager.isActive) {
            try? await assertionManager.acquireAssertion()
        }
        wakeScheduler.scheduleWake(for: schedule)
    } else {
        // On battery — wait
        runtimeState.enforcementState = .waitingForAC
        if await assertionManager.isActive {
            try? await assertionManager.releaseAssertion()
        }
        // Keep wake scheduled in case AC reconnects
    }
}
```

- [ ] **Step 3: Update iconName computed property**

Replace the `iconName` property with:

```swift
var iconName: String {
    switch runtimeState.enforcementState {
    case .active:
        return "bolt.circle.fill"
    case .waitingForAC:
        return "bolt.slash.circle"
    case .failed:
        return "exclamationmark.circle"
    case .idle:
        return "moon.circle"
    }
}
```

- [ ] **Step 4: Run build to verify no errors**

Run: `xcodebuild -project AwakeUtility.xcodeproj -scheme AwakeUtility -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add AwakeUtilityApp/App/AppCoordinator.swift
git commit -m "feat: orchestrate power assertions and wake events

Add 30-second timer to check enforcement state.
Engage assertion when in window + AC.
Release assertion on battery or outside window.
Schedule wake events for window start."
```

---

## Task 8: Update ScheduleEditorView UI

**Files:**
- Modify: `AwakeUtilityApp/Features/ScheduleEditor/ScheduleEditorView.swift:1-119`

- [ ] **Step 1: Replace form fields**

Replace the entire `body` var content with:

```swift
var body: some View {
    Form {
        GroupBox("Wake Window") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Label", text: $label)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Text("Start:")
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                HStack {
                    Text("End:")
                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                DayPicker(selectedDays: $selectedDays)
            }
            .padding(8)
        }

        GroupBox("Power") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Require AC Power", isOn: $requiresAC)
                    .help("Only keep awake when connected to external power")
            }
            .padding(8)
        }

        if let message = validationMessage {
            Text(message)
                .foregroundStyle(.red)
                .font(.caption)
        }
    }
    .formStyle(.grouped)
    .onAppear { loadSchedule() }
    .toolbar {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                coordinator.dismissEditor()
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                saveSchedule()
            }
            .disabled(!isValid)
            .buttonStyle(.borderedProminent)
        }
    }
}
```

- [ ] **Step 2: Add @State vars for start/end time**

Add after `@State private var requiresAC: Bool = true`:

```swift
@State private var startTime: Date = Date()
@State private var endTime: Date = Date()
```

- [ ] **Step 3: Update loadSchedule()**

Replace `loadSchedule()` with:

```swift
private func loadSchedule() {
    label = schedule.label
    selectedDays = schedule.repeatDays
    requiresAC = schedule.requiresACPower

    let calendar = Calendar.current
    startTime = calendar.date(bySettingHour: schedule.startHour, minute: schedule.startMinute, second: 0, of: Date()) ?? Date()
    endTime = calendar.date(bySettingHour: schedule.endHour, minute: schedule.endMinute, second: 0, of: Date()) ?? Date()
}
```

- [ ] **Step 4: Update saveSchedule()**

Replace the `saveSchedule()` method body with:

```swift
var updated = schedule
updated.label = label.trimmingCharacters(in: .whitespaces)
updated.repeatDays = selectedDays
updated.requiresACPower = requiresAC

let calendar = Calendar.current
updated.startHour = calendar.component(.hour, from: startTime)
updated.startMinute = calendar.component(.minute, from: startTime)
updated.endHour = calendar.component(.hour, from: endTime)
updated.endMinute = calendar.component(.minute, from: endTime)

Task {
    await coordinator.saveSchedule(updated)
    coordinator.dismissEditor()
}
```

- [ ] **Step 5: Remove unused @State vars**

Remove these lines:
```swift
@State private var hour: Int = 8
@State private var minute: Int = 0
@State private var leadMinutes: Int = 15
@State private var holdMinutes: Int = 15
@State private var targetTime: Date = Date()
```

- [ ] **Step 6: Run build to verify no errors**

Run: `xcodebuild -project AwakeUtility.xcodeproj -scheme AwakeUtility -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add AwakeUtilityApp/Features/ScheduleEditor/ScheduleEditorView.swift
git commit -m "refactor: update ScheduleEditorView for duration window

Replace lead/hold time pickers with start/end time pickers.
Simplify to single GroupBox for window, one for power."
```

---

## Task 9: Update MenuBarView

**Files:**
- Modify: `AwakeUtilityApp/Features/MenuBar/MenuBarView.swift:1-75`

- [ ] **Step 1: Update statusSection to show window range**

Replace the `statusSection` var with:

```swift
private var statusSection: some View {
    VStack(alignment: .leading, spacing: 4) {
        HStack {
            Image(systemName: coordinator.iconName)
            Text(coordinator.runtimeState.enforcementState.displayName)
                .font(.subheadline)
        }

        if let schedule = await coordinator.scheduleEngine.currentlyEnforcingSchedule(now: Date()) {
            HStack {
                Text(schedule.windowDescription)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }

        HStack {
            Image(systemName: coordinator.runtimeState.powerSource == .ac ? "bolt.fill" : "battery.0")
            Text(coordinator.runtimeState.powerSource == .ac ? "On AC Power" : "On Battery")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
```

- [ ] **Step 2: Run build to verify no errors**

Run: `xcodebuild -project AwakeUtility.xcodeproj -scheme AwakeUtility -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add AwakeUtilityApp/Features/MenuBar/MenuBarView.swift
git commit -m "refactor: update MenuBarView for duration window

Show window range (e.g. '08:00 - 17:00') when enforcing."
```

---

## Task 10: Update ScheduleListView Row

**Files:**
- Modify: `AwakeUtilityApp/Features/ScheduleList/ScheduleListView.swift:72-113`

- [ ] **Step 1: Update ScheduleRow subtitle**

Replace the `body` var content with:

```swift
var body: some View {
    HStack {
        VStack(alignment: .leading, spacing: 2) {
            Text(schedule.label)
                .font(.headline)

            HStack(spacing: 6) {
                Text(schedule.windowDescription)
                Text("·")
                Text(daysDescription)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Circle()
            .fill(schedule.isEnabled ? Color.green : Color.gray)
            .frame(width: 8, height: 8)
    }
    .padding(.vertical, 4)
}
```

- [ ] **Step 2: Run build to verify no errors**

Run: `xcodebuild -project AwakeUtility.xcodeproj -scheme AwakeUtility -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add AwakeUtilityApp/Features/ScheduleList/ScheduleListView.swift
git commit -m "refactor: update ScheduleRow for duration window

Show '08:00 - 17:00 · Every day' instead of single time + lead/hold."
```

---

## Task 11: Implement Data Migration

**Files:**
- Modify: `AwakeUtilityApp/Domain/Models/WakeSchedule.swift:3-42`

- [ ] **Step 1: Add Codable version migration**

Add at end of file, after the struct:

```swift
extension WakeSchedule {
    private enum CodingKeys: String, CodingKey {
        case id, label, isEnabled, startHour, startMinute, endHour, endMinute, repeatDays, requiresACPower
        // Legacy keys for migration
        case hour, minute, leadMinutes, holdMinutes, advancedWakeEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try new format first
        if let startHour = try? container.decode(Int.self, forKey: .startHour) {
            self.id = try container.decode(UUID.self, forKey: .id)
            self.label = try container.decode(String.self, forKey: .label)
            self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
            self.startHour = startHour
            self.startMinute = try container.decode(Int.self, forKey: .startMinute)
            self.endHour = try container.decode(Int.self, forKey: .endHour)
            self.endMinute = try container.decode(Int.self, forKey: .endMinute)
            self.repeatDays = try container.decode(Set<Weekday>.self, forKey: .repeatDays)
            self.requiresACPower = try container.decode(Bool.self, forKey: .requiresACPower)
        } else {
            // Legacy format migration
            self.id = try container.decode(UUID.self, forKey: .id)
            self.label = try container.decode(String.self, forKey: .label)
            self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
            let legacyHour = try container.decode(Int.self, forKey: .hour)
            let legacyMinute = try container.decode(Int.self, forKey: .minute)
            let legacyHoldMinutes = try container.decode(Int.self, forKey: .holdMinutes)

            self.startHour = legacyHour
            self.startMinute = legacyMinute
            // End time = target + hold minutes
            var endTotal = legacyHour * 60 + legacyMinute + legacyHoldMinutes
            if endTotal >= 24 * 60 {
                endTotal = endTotal % (24 * 60)
            }
            self.endHour = endTotal / 60
            self.endMinute = endTotal % 60
            self.repeatDays = try container.decode(Set<Weekday>.self, forKey: .repeatDays)
            self.requiresACPower = try container.decode(Bool.self, forKey: .requiresACPower)
        }
    }
}
```

- [ ] **Step 2: Run build to verify no errors**

Run: `xcodebuild -project AwakeUtility.xcodeproj -scheme AwakeUtility -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Test migration manually**

Run the app with existing `~/Library/Application Support/AwakeUtility/schedules.json` to verify it auto-migrates.

- [ ] **Step 4: Commit**

```bash
git add AwakeUtilityApp/Domain/Models/WakeSchedule.swift
git commit -m "feat: add data migration for legacy schedule format

Auto-migrate hour/minute/leadMinutes/holdMinutes to startHour/startMinute/endHour/endMinute.
Preserve user's existing schedule configuration."
```

---

## Task 12: Final Build and Test

**Files:**
- All files

- [ ] **Step 1: Run full build**

Run: `./build_and_run.sh`
Expected: BUILD SUCCEEDED, app launches

- [ ] **Step 2: Manual test - create schedule**

1. Click menu bar icon
2. Click "Schedules..."
3. Click "+"
4. Set label "Work Hours", start 8:00 AM, end 5:00 PM, select all days
5. Click "Save"
6. Verify schedule appears in list with "08:00 - 17:00 · Every day"

- [ ] **Step 3: Manual test - enforcement**

1. Set system time to 10:00 AM
2. Verify menu bar shows "Active" and "On AC Power"
3. Disconnect AC power
4. Verify menu bar shows "Waiting for AC"
5. Reconnect AC power
6. Verify menu bar shows "Active" again

- [ ] **Step 4: Manual test - overnight window**

1. Create schedule: start 10:00 PM, end 6:00 AM
2. Verify it shows "22:00 - 06:00"
3. Set system time to 2:00 AM
4. Verify enforcement activates

- [ ] **Step 5: Run all tests**

Run: `xcodebuild test -project AwakeUtility.xcodeproj -scheme AwakeUtility -destination 'platform=macOS'`
Expected: All tests PASS

- [ ] **Step 6: Commit final changes**

```bash
git add -A
git commit -m "chore: final integration of duration window wake feature

All manual tests pass. Build successful. Tests passing."
```

---

## Task 13: Push to GitHub

**Files:**
- Git repository

- [ ] **Step 1: Push all commits**

Run: `git push origin main`

Expected: All commits pushed successfully

- [ ] **Step 2: Verify on GitHub**

Open: `https://github.com/kianwoon/AwakeUtility`

Verify all commits appear in the commit history.
