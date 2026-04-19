import Foundation
import IOKit
import IOKit.pwr_mgt

actor PowerAssertionManager: AwakeEnforcing {
    private var _isActive: Bool = false
    private var assertionID: IOPMAssertionID = IOPMAssertionID(0)

    var isActive: Bool { _isActive }

    func acquireAssertion() async throws {
        guard !_isActive else {
            throw AssertionError.alreadyActive
        }

        let reason: CFString = NSString(string: "AwakeUtility keeping Mac awake during scheduled window")
        let assertionType: CFString = NSString(string: kIOPMAssertionTypeNoIdleSleep)
        let result = IOPMAssertionCreateWithName(
            assertionType,
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
