import Foundation

actor DiagnosticsService {
    private let scheduleEngine: ScheduleEngine
    private let logger: LoggerService

    init(scheduleEngine: ScheduleEngine, logger: LoggerService) {
        self.scheduleEngine = scheduleEngine
        self.logger = logger
    }

    func collectDiagnostics(
        runtimeState: RuntimeState
    ) async -> AppDiagnostics {
        let allSchedules = await scheduleEngine.allSchedules
        let enabled = allSchedules.filter(\.isEnabled)
        let recent = await logger.recentLogs(limit: 20)

        return AppDiagnostics(
            powerSource: runtimeState.powerSource,
            enforcementState: runtimeState.enforcementState,
            activeAssertion: runtimeState.activeAssertion,
            lastSleepAt: runtimeState.lastSleepAt,
            lastWakeAt: runtimeState.lastWakeAt,
            lastFailureReason: runtimeState.lastFailureReason,
            scheduleCount: allSchedules.count,
            enabledScheduleCount: enabled.count,
            recentLogs: recent
        )
    }
}
