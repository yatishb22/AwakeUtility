import Foundation

struct SleepEvent: Equatable {
    enum EventType {
        case sleep
        case wake
    }

    let type: EventType
    let timestamp: Date
}

protocol SleepEventObserving {
    var events: AsyncStream<SleepEvent> { get }
}
