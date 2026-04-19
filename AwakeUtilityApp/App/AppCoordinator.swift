import SwiftUI

@Observable
@MainActor
final class AppCoordinator {

    var runtimeState = RuntimeState()
    var schedules: [WakeSchedule] = []
    var showingScheduleEditor = false
    var editingSchedule: WakeSchedule?

    private let scheduleEngine = ScheduleEngine()
    let scheduleRepository = JSONScheduleRepository()
    let powerMonitor = PowerSourceMonitor.shared
    let assertionManager = PowerAssertionManager()
    let logger = LocalLogger()

    private static let schedulesFileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("AwakeUtility", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("schedules.json")
    }()

    init() {
        schedules = Self.loadSchedulesSync()
        runtimeState.powerSource = PowerSourceMonitor.readPowerSource()
    }

    var iconName: String {
        switch runtimeState.enforcementState {
        case .enforcing, .holdWindow:
            return "bolt.circle.fill"
        case .scheduled:
            return "clock.circle"
        case .waitingForPower:
            return "bolt.slash.circle"
        case .failed:
            return "exclamationmark.circle"
        case .idle:
            return "moon.circle"
        }
    }

    func start() async {
        NSLog("[AwakeUtility] start() called")
        powerMonitor.startMonitoring()
        let initial = await powerMonitor.currentPowerSource
        NSLog("[AwakeUtility] Initial power source: \(initial.rawValue)")
        runtimeState.powerSource = initial

        Task { @MainActor in
            for await state in powerMonitor.powerSourceUpdates {
                NSLog("[AwakeUtility] Power source changed: \(state.rawValue)")
                runtimeState.powerSource = state
            }
        }

        await refreshRuntimeState()
        NSLog("[AwakeUtility] start() done. enforcement=\(runtimeState.enforcementState.displayName) power=\(runtimeState.powerSource.rawValue)")
    }

    func loadSchedules() async {
        do {
            schedules = try await scheduleRepository.loadAll()
            await scheduleEngine.reload(schedules)
        } catch {
            logger.log(LogEvent(type: .error, message: "Failed to load schedules: \(error.localizedDescription)"))
        }
    }

    func saveSchedule(_ schedule: WakeSchedule) async {
        do {
            try await scheduleRepository.save(schedule)
            schedules = try await scheduleRepository.loadAll()
            await scheduleEngine.reload(schedules)
        } catch {
            logger.log(LogEvent(type: .error, message: "Failed to save schedule: \(error.localizedDescription)"))
        }
    }

    func deleteSchedule(_ id: UUID) async {
        do {
            try await scheduleRepository.delete(id)
            schedules = try await scheduleRepository.loadAll()
            await scheduleEngine.reload(schedules)
        } catch {
            logger.log(LogEvent(type: .error, message: "Failed to delete schedule: \(error.localizedDescription)"))
        }
    }

    func createNewSchedule() {
        editingSchedule = WakeSchedule()
        showingScheduleEditor = true
    }

    func openScheduleEditor(for schedule: WakeSchedule) {
        editingSchedule = schedule
        showingScheduleEditor = true
    }

    func dismissEditor() {
        showingScheduleEditor = false
        editingSchedule = nil
    }

    func refreshRuntimeState() async {
        let next = await scheduleEngine.nextActiveSchedule(now: Date())
        let window = await scheduleEngine.windowForNextSchedule(now: Date())

        runtimeState.nextScheduleID = next?.id
        runtimeState.nextTrigger = window?.targetTime

        if next != nil {
            runtimeState.enforcementState = .scheduled
        } else {
            runtimeState.enforcementState = .idle
        }
    }

    private static func loadSchedulesSync() -> [WakeSchedule] {
        guard FileManager.default.fileExists(atPath: schedulesFileURL.path),
              let data = try? Data(contentsOf: schedulesFileURL),
              let decoded = try? JSONDecoder().decode([WakeSchedule].self, from: data) else {
            return []
        }
        return decoded
    }
}
