# Apple Silicon macOS Awake Utility — `plan.md`

## 1) Project goal

Build a **small macOS menu bar utility** for **Apple silicon MacBooks only** that helps ensure the Mac is **awake at a user-configured time**, **only when connected to external power**.

This project must be designed around **reliable behavior** on modern macOS, not outdated Intel-era assumptions.

### Product truth
This app is **not** a guaranteed firmware-level wake scheduler.

It is an **awake assurance utility**:
- it detects upcoming scheduled times
- checks whether the Mac is on external power
- uses supported power-management techniques to keep the Mac awake before the target time
- optionally provides an **advanced best-effort scheduled wake path** later

---

## 2) Product scope

### In scope (MVP)
- Apple silicon MacBooks only
- Menu bar app
- User-configurable schedules
- Recurring schedules
- External power detection
- Lead-time awake enforcement
- Diagnostics panel
- Login persistence
- Local logging

### Out of scope (MVP)
- Intel support
- Wake from shutdown
- Guaranteed deep-sleep timed wake with lid closed
- Private framework dependency for core function
- App Store-first packaging
- Cloud sync

### Later phase
- Privileged helper
- Advanced scheduled wake registration
- Better clamshell diagnostics
- Optional `pmset` integration for advanced users

---

## 3) Target platform

- **Hardware:** Apple silicon MacBooks (M1/M2/M3/M4 family)
- **OS target:** macOS Sequoia 15+
- **Language:** Swift 5.10+
- **UI:** SwiftUI
- **App type:** Menu bar utility (`MenuBarExtra`)

---

## 4) High-level approach

### Default strategy (reliable)
Use a **lead window** before the configured target time.

Example:
- User sets target time: **8:55 AM**
- Lead window: **15 min**
- At **8:40 AM**, if on AC power, the app acquires a power assertion to keep the Mac awake
- At **8:55 AM**, the Mac should already be awake
- At **9:10 AM**, the app releases the assertion if no overlapping schedule exists

### Advanced strategy (later)
Optionally attempt system scheduled wake using public power APIs and/or `pmset`, but treat it as **best effort only**.

---

## 5) Engineering principles

1. **Reliability over cleverness**  
   Do not build core behavior on unsupported hacks.

2. **Visibility over false promises**  
   Always show exact status: waiting for AC, keeping awake, missed window, advanced wake failed, etc.

3. **Small clean modules**  
   Keep schedule logic, power monitoring, enforcement, and UI separated.

4. **Agent-friendly codebase**  
   The repo should be easy for AI coding agents to navigate and extend.

5. **Local-first**  
   No network dependency for MVP.

---

## 6) Functional requirements

### FR-1 Schedule management
The user can:
- create schedule
- edit schedule
- delete schedule
- enable/disable schedule
- define recurring days
- set lead minutes
- set hold minutes
- choose “AC power required”

### FR-2 Power gating
The app must only enforce awake behavior when:
- external power is connected

### FR-3 Awake enforcement
The app must:
- compute next trigger time
- enter lead window before target
- acquire power assertion
- release assertion when done

### FR-4 Login persistence
The app must relaunch at login and restore schedules/state.

### FR-5 Diagnostics
The app must show:
- next trigger
- power source
- active assertion state
- last wake/sleep events
- last failure reason

### FR-6 Logging
The app must log:
- schedule activation
- assertion create/release
- power source changes
- sleep/wake transitions
- failure cases

---

## 7) Non-functional requirements

### NFR-1 Reliability
Core function should work predictably in the supported lead-window assertion model.

### NFR-2 Low overhead
The app must be lightweight and suitable as a persistent menu bar utility.

### NFR-3 Safe failure mode
If conditions are not met, the app must fail clearly and transparently.

### NFR-4 Maintainability
Code should use protocols and small services to support future extension.

### NFR-5 Observability
All important state transitions must be visible in logs and the diagnostics UI.

---

## 8) Repo structure

```text
AwakeUtility/
├─ AwakeUtilityApp.swift
├─ App/
│  ├─ AppCoordinator.swift
│  ├─ AppEnvironment.swift
│  └─ LaunchAtLoginManager.swift
├─ Domain/
│  ├─ Models/
│  │  ├─ WakeSchedule.swift
│  │  ├─ RuntimeState.swift
│  │  ├─ PowerSourceState.swift
│  │  ├─ EnforcementState.swift
│  │  └─ AppDiagnostics.swift
│  ├─ Protocols/
│  │  ├─ ScheduleRepository.swift
│  │  ├─ PowerMonitoring.swift
│  │  ├─ AwakeEnforcing.swift
│  │  ├─ SleepEventObserving.swift
│  │  └─ LoggerService.swift
│  └─ Services/
│     ├─ ScheduleEngine.swift
│     ├─ TriggerCalculator.swift
│     └─ DiagnosticsService.swift
├─ Infrastructure/
│  ├─ Power/
│  │  ├─ PowerSourceMonitor.swift
│  │  ├─ PowerAssertionManager.swift
│  │  ├─ SleepEventObserver.swift
│  │  └─ AdvancedWakeScheduler.swift
│  ├─ Persistence/
│  │  ├─ JSONScheduleRepository.swift
│  │  └─ SettingsStore.swift
│  └─ Logging/
│     ├─ LocalLogger.swift
│     └─ LogEvent.swift
├─ Features/
│  ├─ MenuBar/
│  │  ├─ MenuBarView.swift
│  │  └─ MenuBarViewModel.swift
│  ├─ ScheduleList/
│  │  ├─ ScheduleListView.swift
│  │  └─ ScheduleListViewModel.swift
│  ├─ ScheduleEditor/
│  │  ├─ ScheduleEditorView.swift
│  │  └─ ScheduleEditorViewModel.swift
│  ├─ Diagnostics/
│  │  ├─ DiagnosticsView.swift
│  │  └─ DiagnosticsViewModel.swift
│  └─ Settings/
│     ├─ SettingsView.swift
│     └─ SettingsViewModel.swift
├─ Resources/
│  └─ Defaults.plist
└─ Tests/
   ├─ ScheduleEngineTests.swift
   ├─ TriggerCalculatorTests.swift
   ├─ PowerAssertionManagerTests.swift
   └─ RuntimeStateReducerTests.swift
```

---

## 9) Core domain models

### `WakeSchedule`
```swift
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
}
```

### `PowerSourceState`
```swift
enum PowerSourceState: String, Codable {
    case ac
    case battery
    case unknown
}
```

### `EnforcementState`
```swift
enum EnforcementState: String, Codable {
    case idle
    case waitingForPower
    case scheduled
    case enforcing
    case holdWindow
    case failed
}
```

### `RuntimeState`
```swift
struct RuntimeState: Codable {
    var powerSource: PowerSourceState
    var enforcementState: EnforcementState
    var nextScheduleID: UUID?
    var nextTrigger: Date?
    var activeAssertion: Bool
    var lastSleepAt: Date?
    var lastWakeAt: Date?
    var lastFailureReason: String?
}
```

---

## 10) Component responsibilities

### 10.1 AppCoordinator
Owns startup flow and wires all services together.

Responsibilities:
- initialize repositories/services
- restore schedules
- subscribe to power updates
- subscribe to sleep/wake notifications
- kick scheduler loop

### 10.2 ScheduleEngine
Responsible for schedule selection and timing decisions.

Responsibilities:
- load enabled schedules
- compute next active schedule
- determine whether current time is inside lead / hold window
- handle overlapping schedules

### 10.3 TriggerCalculator
Pure logic for computing next trigger dates.

Responsibilities:
- recurring day matching
- next occurrence computation
- lead/hold window math

### 10.4 PowerSourceMonitor
Tracks current power source.

Responsibilities:
- detect AC vs battery
- publish state changes
- support periodic verification fallback

### 10.5 PowerAssertionManager
Controls awake enforcement.

Responsibilities:
- create sleep-prevention assertion
- release assertion safely
- report status
- guard against duplicate assertion leaks

### 10.6 SleepEventObserver
Observes sleep/wake transitions.

Responsibilities:
- listen for sleep/wake events
- update runtime state
- trigger re-evaluation after wake

### 10.7 DiagnosticsService
Collects runtime status for UI and debugging.

Responsibilities:
- summarize current state
- expose last errors
- aggregate latest system observations

### 10.8 LocalLogger
Writes structured local logs.

Responsibilities:
- append JSON log events
- rotate logs
- provide recent log tail for diagnostics panel

---

## 11) State machine

```text
idle
 ├─(schedule available)──────────────> scheduled
 ├─(no enabled schedule)─────────────> idle

scheduled
 ├─(lead window enters + AC power)───> enforcing
 ├─(lead window enters + no AC)──────> waitingForPower
 ├─(schedule disabled)───────────────> idle

waitingForPower
 ├─(AC connected within lead window)─> enforcing
 ├─(target missed)───────────────────> failed
 ├─(schedule removed)────────────────> idle

enforcing
 ├─(target reached)──────────────────> holdWindow
 ├─(assertion failed)────────────────> failed
 ├─(schedule cancelled)──────────────> idle

holdWindow
 ├─(hold complete)───────────────────> scheduled / idle
 ├─(overlapping schedule)────────────> enforcing

failed
 ├─(next schedule recalculated)──────> scheduled / idle
```

---

## 12) MVP implementation phases

## Phase 0 — Bootstrap
Goal: create app shell and clean architecture skeleton.

Tasks:
- create Xcode project
- set deployment target to macOS 15+
- create menu bar app shell
- create base folder/module structure
- define domain models
- define service protocols
- add sample mock data

Deliverable:
- app launches and menu bar icon appears

---

## Phase 1 — Schedule domain
Goal: implement schedule CRUD and trigger calculation.

Tasks:
- implement `WakeSchedule`
- implement `Weekday`
- implement `TriggerCalculator`
- implement `ScheduleEngine`
- implement JSON persistence for schedules
- add schedule list/editor UI
- add validation rules

Validation rules:
- leadMinutes >= 1
- holdMinutes >= 0
- at least one repeat day for recurring schedule
- no invalid hour/minute values

Deliverable:
- user can create schedules and app can compute next trigger

---

## Phase 2 — Power source detection
Goal: detect AC power reliably.

Tasks:
- implement `PowerSourceMonitor`
- expose observable power state
- test AC/battery transitions
- display current power state in menu bar and diagnostics panel

Deliverable:
- app accurately knows whether Mac is on AC or battery

---

## Phase 3 — Awake enforcement
Goal: enforce awake state in lead window.

Tasks:
- implement `PowerAssertionManager`
- add acquire/release lifecycle
- wire schedule engine to assertion manager
- protect against duplicate assertions
- expose runtime state to UI

Behavior:
- when lead window starts and AC is present -> acquire assertion
- when hold window ends -> release assertion
- if AC is absent -> do not acquire assertion

Deliverable:
- app can keep Mac awake for the configured schedule window

---

## Phase 4 — Sleep/wake observation
Goal: react properly to system transitions.

Tasks:
- implement `SleepEventObserver`
- capture last sleep/wake timestamps
- trigger state re-evaluation on wake
- log all transitions

Deliverable:
- app handles state recalculation after wake and records transitions

---

## Phase 5 — Diagnostics + logging
Goal: make the app explain itself.

Tasks:
- implement `LocalLogger`
- define structured log event model
- build diagnostics panel
- show:
  - next schedule
  - active assertion
  - power source
  - last sleep/wake
  - last failure reason
  - recent logs

Deliverable:
- user can see why the app is or isn’t enforcing awake state

---

## Phase 6 — Launch at login
Goal: make the utility practical.

Tasks:
- implement login item support
- restore schedules on app relaunch
- restore runtime state

Deliverable:
- app starts automatically after login and resumes monitoring

---

## Phase 7 — Hardening
Goal: stabilize edge cases.

Tasks:
- overlapping schedules logic
- assertion leak prevention
- missed schedule handling
- low-noise menu bar updates
- more robust persistence error handling
- test suspend/resume edge cases

Deliverable:
- MVP stable enough for personal daily use

---

## 13) Phase 2 plan (advanced mode)

### Goal
Add an optional best-effort scheduled wake path.

### Tasks
- design privileged helper boundary
- add advanced mode setting
- attempt scheduled power event registration
- verify registration
- add advanced diagnostics
- log permission failures clearly

### Important rule
Advanced mode must not replace lead-window awake enforcement.
It is supplemental only.

---

## 14) AI coding execution plan

Use the following build order with your AI coding agent.

### Step 1
Generate project skeleton and folder structure.

### Step 2
Implement pure domain models and `TriggerCalculator` first.

### Step 3
Write unit tests for schedule math before wiring UI.

### Step 4
Build schedule CRUD UI.

### Step 5
Implement power source monitor.

### Step 6
Implement power assertion manager.

### Step 7
Wire runtime state into menu bar UI.

### Step 8
Implement diagnostics panel and logging.

### Step 9
Add launch-at-login support.

### Step 10
Run manual scenario tests and fix edge cases.

---

## 15) Suggested AI coding prompts

### Prompt A — project bootstrap
```text
Create a macOS SwiftUI menu bar app for Apple silicon Macs only.
Use a clean architecture with folders for App, Domain, Infrastructure, Features, and Tests.
Define protocols for schedule repository, power monitor, awake enforcement, sleep event observer, and logger.
Generate buildable skeleton code with placeholder implementations.
```

### Prompt B — schedule engine
```text
Implement a pure Swift schedule engine for recurring wake schedules.
Requirements:
- compute next trigger date
- support repeat days
- support lead and hold windows
- handle overlapping schedules deterministically
- include unit tests
Do not use UI code.
```

### Prompt C — power monitor
```text
Implement a macOS power source monitor in Swift.
It must publish whether the Mac is on AC power, battery, or unknown.
Wrap system APIs behind a PowerMonitoring protocol.
Add a mock implementation for tests and previews.
```

### Prompt D — assertion manager
```text
Implement a PowerAssertionManager in Swift for macOS.
It must acquire and release a power assertion safely, prevent duplicate assertions, and expose current status.
Wrap system-specific calls behind a protocol so the logic is testable.
```

### Prompt E — diagnostics panel
```text
Build a SwiftUI diagnostics view for the menu bar app.
Show current power source, next trigger, enforcement state, active assertion, last sleep/wake timestamps, last failure reason, and recent log entries.
```

---

## 16) Testing strategy

### Unit tests
- next trigger calculation
- recurring schedule selection
- lead/hold window logic
- overlapping schedule resolution
- runtime state transitions

### Integration tests
- AC -> battery transition during lead window
- app launch with existing schedules
- assertion acquire/release workflow
- wake event causing recalculation

### Manual tests
1. AC connected, lid open, target in 10 min
2. AC connected, lid closed after assertion active
3. Battery only, target arrives
4. Schedule disabled mid-window
5. App relaunched during active schedule
6. Two schedules overlap

---

## 17) Key risks

### Risk 1 — Apple silicon power behavior
Closed-lid and sleep behavior may differ across devices and OS versions.

Mitigation:
- keep the core product promise narrow
- use diagnostics heavily
- test on multiple Apple silicon machines

### Risk 2 — False user expectation
Users may think this is BIOS-level wake scheduling.

Mitigation:
- clear wording in UI
- default to “ensure awake at scheduled time”

### Risk 3 — Assertion leaks
A buggy assertion lifecycle can keep the Mac awake unexpectedly.

Mitigation:
- centralized assertion manager
- defensive release on startup/shutdown path
- structured logs

### Risk 4 — Advanced mode privilege friction
Scheduled power events may require elevated permissions.

Mitigation:
- keep this out of MVP
- make advanced mode explicitly optional

---

## 18) Definition of done for MVP

MVP is done when:
- app runs as a menu bar utility
- user can create and edit schedules
- app correctly computes next schedule
- app detects AC power reliably
- app acquires awake enforcement in lead window
- app releases enforcement after hold window
- app shows current state in diagnostics
- app logs critical events
- app relaunches at login
- app is stable in daily personal use

---

## 19) Recommended first coding sprint

### Sprint 1 goal
Build the smallest end-to-end version that proves the core workflow.

### Sprint 1 deliverables
- menu bar app shell
- one hardcoded schedule
- power source detection
- lead-window enforcement
- basic status UI
- console logging

### Sprint 1 success criteria
You can set a near-future schedule and observe:
- app detects AC power
- app enters enforcement window
- app reports active awake enforcement
- app exits enforcement window cleanly

---

## 20) Immediate next task for AI coding agent

Start with this exact instruction:

```text
Build Phase 0 and Phase 1 of this macOS Apple silicon menu bar utility.
Generate a clean SwiftUI project structure with:
- domain models
- schedule repository protocol
- JSON schedule persistence
- TriggerCalculator
- ScheduleEngine
- schedule list view
- schedule editor view
- unit tests for trigger calculation
Keep all system power APIs mocked for now.
The project must compile.
```

---

## 21) Final note

Do not over-engineer the first cut.

The real value is proving this loop works cleanly:
- schedule
- AC power gate
- lead window
- awake enforcement
- diagnostics

Once that is solid, the rest becomes manageable.
