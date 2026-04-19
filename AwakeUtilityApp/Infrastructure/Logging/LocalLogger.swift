import Foundation

@MainActor
final class LocalLogger: LoggerService {
    private var logs: [LogEvent] = []
    private let maxStoredLogs = 500

    func log(_ event: LogEvent) {
        logs.append(event)
        if logs.count > maxStoredLogs {
            logs.removeFirst(logs.count - maxStoredLogs)
        }
        print("[\(event.type.rawValue)] \(event.message)")
    }

    func recentLogs(limit: Int = 50) -> [LogEvent] {
        Array(logs.suffix(limit))
    }
}
