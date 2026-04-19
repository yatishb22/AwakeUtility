import Foundation

struct RuntimeState: Codable {
    var powerSource: PowerSourceState
    var enforcementState: EnforcementState
    var nextScheduleID: UUID?
    var nextTrigger: Date?
    var activeAssertion: Bool
    var lastSleepAt: Date?
    var lastWakeAt: Date?
    var lastFailureReason: String?

    init(
        powerSource: PowerSourceState = .unknown,
        enforcementState: EnforcementState = .idle,
        nextScheduleID: UUID? = nil,
        nextTrigger: Date? = nil,
        activeAssertion: Bool = false,
        lastSleepAt: Date? = nil,
        lastWakeAt: Date? = nil,
        lastFailureReason: String? = nil
    ) {
        self.powerSource = powerSource
        self.enforcementState = enforcementState
        self.nextScheduleID = nextScheduleID
        self.nextTrigger = nextTrigger
        self.activeAssertion = activeAssertion
        self.lastSleepAt = lastSleepAt
        self.lastWakeAt = lastWakeAt
        self.lastFailureReason = lastFailureReason
    }
}
