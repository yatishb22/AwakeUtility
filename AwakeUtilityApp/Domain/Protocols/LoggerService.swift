import Foundation

protocol LoggerService {
    func log(_ event: LogEvent)
    func recentLogs(limit: Int) async -> [LogEvent]
}
