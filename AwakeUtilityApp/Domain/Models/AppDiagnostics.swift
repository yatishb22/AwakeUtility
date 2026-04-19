import Foundation

struct AppDiagnostics {
    var powerSource: PowerSourceState
    var enforcementState: EnforcementState
    var nextTrigger: Date?
    var activeAssertion: Bool
    var lastSleepAt: Date?
    var lastWakeAt: Date?
    var lastFailureReason: String?
    var scheduleCount: Int
    var enabledScheduleCount: Int
    var recentLogs: [LogEvent]

    static let empty = AppDiagnostics(
        powerSource: .unknown,
        enforcementState: .idle,
        nextTrigger: nil,
        activeAssertion: false,
        lastSleepAt: nil,
        lastWakeAt: nil,
        lastFailureReason: nil,
        scheduleCount: 0,
        enabledScheduleCount: 0,
        recentLogs: []
    )
}
