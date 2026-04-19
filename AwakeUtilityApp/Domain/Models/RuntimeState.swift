import Foundation

struct RuntimeState: Codable {
    var powerSource: PowerSourceState
    var enforcementState: EnforcementState
    var activeAssertion: Bool
    var lastSleepAt: Date?
    var lastWakeAt: Date?
    var lastFailureReason: String?

    init(
        powerSource: PowerSourceState = .unknown,
        enforcementState: EnforcementState = .idle,
        activeAssertion: Bool = false,
        lastSleepAt: Date? = nil,
        lastWakeAt: Date? = nil,
        lastFailureReason: String? = nil
    ) {
        self.powerSource = powerSource
        self.enforcementState = enforcementState
        self.activeAssertion = activeAssertion
        self.lastSleepAt = lastSleepAt
        self.lastWakeAt = lastWakeAt
        self.lastFailureReason = lastFailureReason
    }
}
