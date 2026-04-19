import Testing
import Foundation
@testable import AwakeUtility

struct PowerAssertionManagerTests {

    @Test("Acquire assertion sets active state")
    func acquireSetsActive() async {
        let manager = PowerAssertionManager()
        #expect(!(await manager.isActive))

        try? await manager.acquireAssertion()
        #expect(await manager.isActive)
    }

    @Test("Release assertion clears active state")
    func releaseClearsActive() async {
        let manager = PowerAssertionManager()
        try? await manager.acquireAssertion()
        #expect(await manager.isActive)

        try? await manager.releaseAssertion()
        #expect(!(await manager.isActive))
    }

    @Test("Acquire twice returns error")
    func acquireTwiceThrows() async {
        let manager = PowerAssertionManager()
        try? await manager.acquireAssertion()

        do {
            try await manager.acquireAssertion()
            #expect(Bool(false), "Expected error but call succeeded")
        } catch {
            #expect(true)
        }
    }

    @Test("Release without acquire returns error")
    func releaseWithoutAcquireThrows() async {
        let manager = PowerAssertionManager()

        do {
            try await manager.releaseAssertion()
            #expect(Bool(false), "Expected error but call succeeded")
        } catch {
            #expect(true)
        }
    }
}
