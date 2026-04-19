import Foundation

actor JSONScheduleRepository: ScheduleRepository {
    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    private static var defaultFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("AwakeUtility", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("schedules.json")
    }

    convenience init() {
        self.init(fileURL: Self.defaultFileURL)
    }

    func loadAll() async throws -> [WakeSchedule] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        let schedules = try JSONDecoder().decode([WakeSchedule].self, from: data)
        return schedules
    }

    func save(_ schedule: WakeSchedule) async throws {
        var schedules = try await loadAll()
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
        } else {
            schedules.append(schedule)
        }
        try writeSchedules(schedules)
    }

    func delete(_ id: UUID) async throws {
        var schedules = try await loadAll()
        schedules.removeAll { $0.id == id }
        try writeSchedules(schedules)
    }

    private func writeSchedules(_ schedules: [WakeSchedule]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(schedules)
        try data.write(to: fileURL, options: .atomic)
    }
}
