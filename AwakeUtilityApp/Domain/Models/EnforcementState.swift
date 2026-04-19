import Foundation

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
