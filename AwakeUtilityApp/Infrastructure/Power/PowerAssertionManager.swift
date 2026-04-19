import Foundation

actor PowerAssertionManager: AwakeEnforcing {
    private var _isActive: Bool = false
    private var assertionID: String?

    var isActive: Bool { _isActive }

    func acquireAssertion() async throws {
        guard !_isActive else {
            throw AssertionError.alreadyActive
        }

        assertionID = UUID().uuidString
        _isActive = true
    }

    func releaseAssertion() async throws {
        guard _isActive else {
            throw AssertionError.notActive
        }

        assertionID = nil
        _isActive = false
    }

    enum AssertionError: LocalizedError {
        case alreadyActive
        case notActive

        var errorDescription: String? {
            switch self {
            case .alreadyActive: return "Assertion already active"
            case .notActive: return "No active assertion to release"
            }
        }
    }
}
