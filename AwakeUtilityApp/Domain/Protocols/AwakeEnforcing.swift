import Foundation

protocol AwakeEnforcing {
    var isActive: Bool { get async }
    func acquireAssertion() async throws
    func releaseAssertion() async throws
}
