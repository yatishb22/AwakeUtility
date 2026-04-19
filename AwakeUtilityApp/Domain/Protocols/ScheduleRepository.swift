import Foundation

protocol ScheduleRepository {
    func loadAll() async throws -> [WakeSchedule]
    func save(_ schedule: WakeSchedule) async throws
    func delete(_ id: UUID) async throws
}
