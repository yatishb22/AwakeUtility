# Duration Window Wake Feature

## Summary

Replace the single-point-in-time schedule with a duration window (e.g. 8 AM - 5 PM). During the window, if on AC power, the Mac stays awake and wakes from sleep/shutdown automatically.

## Requirements

- User defines a start time and end time (duration window)
- During the active window + AC power: prevent sleep, wake from sleep, schedule power-on from shutdown
- During the active window + battery: do nothing (allow normal sleep)
- If AC reconnects mid-window: re-engage wake behavior
- Single schedule only (simplify UI)
- Support overnight windows (e.g. 10 PM - 6 AM)
- Migrate existing schedules.json data

## Model Changes

### WakeSchedule

Remove: `hour`, `minute`, `leadMinutes`, `holdMinutes`, `advancedWakeEnabled`
Add: `startHour`, `startMinute`, `endHour`, `endMinute`
Keep: `id`, `label`, `isEnabled`, `repeatDays`, `requiresACPower`

### EnforcementState

Replace current 6-case enum with 4 cases:
- `.idle` - no active window
- `.active` - in window + on AC + assertion held
- `.waitingForAC` - in window but on battery
- `.failed` - assertion error

### TriggerCalculator

Replace lead/hold window logic with range check:
- `isInActiveWindow(startHour, startMinute, endHour, endMinute, repeatDays, now) -> Bool`
- Handle overnight windows where end < start (e.g. 22:00 - 06:00 means the window spans midnight)
- When start == end, treat as a 24-hour window (all day)
- Remove: `Window` struct, `nextTargetDate`, `computeWindow`, `isInLeadWindow`, `isInHoldWindow`

## Power Assertion + Wake Scheduling

### PowerAssertionManager (update)

Replace stub with real IOKit calls:
- `acquireAssertion()` -> `IOPMAssertionCreateWithName(kIOPMAssertionTypeNoIdleSleep, name, assertionID)`
- `releaseAssertion()` -> `IOPMAssertionRelease(assertionID)`
- Track IOPMAssertionID for lifecycle management

### WakeScheduler (new component)

- Schedule one-time wake events via `IOPMSchedulePowerEvent(date, .wake)`
- On app launch: schedule wake at window start for today or tomorrow
- On window end: cancel via `IOPMCancelScheduledPowerEvent`
- Refresh schedule daily and when schedules change

### AppCoordinator Orchestration

Every ~30 seconds timer + power source change listener:

1. In window + AC -> acquire assertion, ensure wake event scheduled
2. In window + battery -> release assertion, keep wake event scheduled
3. Outside window -> release assertion, cancel wake event

Power source changes from `powerSourceUpdates` stream trigger immediate re-check.

## UI Changes

### ScheduleEditorView

GroupBox "Wake Window":
- Label (TextField)
- Start time (DatePicker, hour+minute)
- End time (DatePicker, hour+minute)
- Repeat days (existing DayPicker)

GroupBox "Power":
- Require AC Power (Toggle, default ON)

Remove: lead time stepper, hold time stepper, advanced wake toggle

### MenuBarView

- Show window range: "8:00 AM - 5:00 PM"
- Show state: "Active / On AC Power" or "Waiting for AC" or "Idle"

### ScheduleListView / ScheduleRow

- Show "8:00 AM - 5:00 PM . Every day" in subtitle
- Remove "AC Required" badge (AC is always required)

### DiagnosticsView

No changes needed.

## Data Migration

Custom Codable with version detection:
- On decode: detect old format (has `hour`/`minute` but no `startHour`/`startMinute`)
- Auto-migrate: `startHour = hour`, `startMinute = minute`, `endHour = hour`, `endMinute = minute + holdMinutes`
- Write new format back to disk on first load
