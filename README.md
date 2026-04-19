# AwakeUtility

A macOS menu bar app for Apple Silicon MacBooks that keeps your Mac awake during scheduled time windows and automatically wakes it from sleep.

## Features

- **Duration window scheduling** — Define a time range (e.g. 8:00 AM – 5:00 PM) during which your Mac stays awake
- **Automatic wake from sleep** — Schedules hardware-level wake events so your Mac powers on at window start
- **AC power awareness** — Optionally require AC power; releases the sleep assertion on battery
- **Overnight windows** — Supports overnight ranges (e.g. 10:00 PM – 6:00 AM)
- **Repeat day selection** — Choose which days of the week each schedule is active
- **Menu bar status** — Shows current enforcement state and power source at a glance

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon Mac (designed for MacBook power management)
- Xcode 16+ (for building from source)

## Building

```bash
git clone https://github.com/kianwoon/AwakeUtility.git
cd AwakeUtility
xcodebuild -project AwakeUtility.xcodeproj -scheme AwakeUtility -configuration Debug build
```

Or use the included build script to build and launch:

```bash
bash build_and_run.sh
```

## How It Works

| Component | Technology |
|-----------|-----------|
| Prevent sleep | `IOPMAssertionCreateWithName` (NoIdleSleep assertion) |
| Schedule wake | `IOPMSchedulePowerEvent` (hardware wake timer) |
| Detect power source | `IOPSCopyPowerSourcesInfo` (IOKit power source API) |
| Wake-from-sleep recovery | `NSWorkspace.didWakeNotification` |

The app maintains a 30-second heartbeat that checks whether the current time falls within any enabled schedule window. When inside a window on AC power, it holds a power assertion to prevent system sleep. When the Mac wakes from sleep, it immediately reschedules the next wake event so there's always one pending.

## Architecture

```
AwakeUtilityApp/
├── App/
│   └── AppCoordinator.swift       # Orchestration: timer, assertions, wake scheduling
├── Domain/
│   ├── Models/                    # WakeSchedule, EnforcementState, RuntimeState
│   ├── Protocols/                 # AwakeEnforcing, ScheduleRepository, etc.
│   └── Services/                  # ScheduleEngine, TriggerCalculator
├── Features/
│   ├── MenuBar/                   # Menu bar popover UI
│   ├── ScheduleEditor/            # Schedule creation/editing form
│   ├── ScheduleList/              # Schedule list with NavigationSplitView
│   └── Diagnostics/               # Diagnostics view
├── Infrastructure/
│   ├── Power/
│   │   ├── PowerAssertionManager.swift  # IOKit sleep assertion
│   │   ├── WakeScheduler.swift          # IOPMSchedulePowerEvent
│   │   └── PowerSourceMonitor.swift     # AC/battery detection
│   └── Persistence/
│       └── JSONScheduleRepository.swift # JSON file storage
└── Tests/
    ├── PowerAssertionManagerTests.swift
    ├── ScheduleEngineTests.swift
    └── TriggerCalculatorTests.swift
```

## License

MIT
