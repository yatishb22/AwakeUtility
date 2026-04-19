import Foundation

enum EnforcementState: String, Codable {
    case idle
    case waitingForPower
    case scheduled
    case enforcing
    case holdWindow
    case failed

    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .waitingForPower: return "Waiting for AC Power"
        case .scheduled: return "Scheduled"
        case .enforcing: return "Keeping Awake"
        case .holdWindow: return "Hold Window"
        case .failed: return "Failed"
        }
    }

    var isActive: Bool {
        self == .enforcing || self == .holdWindow
    }
}
