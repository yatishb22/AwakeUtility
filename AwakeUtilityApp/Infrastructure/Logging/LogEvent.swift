import Foundation

enum LogEventType: String, Codable {
    case scheduleActivated
    case scheduleDeactivated
    case assertionAcquired
    case assertionReleased
    case assertionFailed
    case powerSourceChanged
    case sleepEvent
    case wakeEvent
    case scheduleMissed
    case stateTransition
    case error
}

struct LogEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: LogEventType
    let message: String
    let details: [String: String]?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: LogEventType,
        message: String,
        details: [String: String]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.message = message
        self.details = details
    }
}
