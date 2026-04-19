import Foundation

@MainActor
final class SleepEventObserver: SleepEventObserving {
    private var continuation: AsyncStream<SleepEvent>.Continuation?

    var events: AsyncStream<SleepEvent> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func simulateSleep() {
        continuation?.yield(SleepEvent(type: .sleep, timestamp: Date()))
    }

    func simulateWake() {
        continuation?.yield(SleepEvent(type: .wake, timestamp: Date()))
    }
}
