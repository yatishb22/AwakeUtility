import SwiftUI

struct ScheduleListView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var selectedSchedule: WakeSchedule?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSchedule) {
                ForEach(coordinator.schedules) { schedule in
                    ScheduleRow(schedule: schedule)
                        .tag(schedule)
                        .contextMenu {
                            Button("Edit") {
                                coordinator.openScheduleEditor(for: schedule)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                Task {
                                    await coordinator.deleteSchedule(schedule.id)
                                    if selectedSchedule?.id == schedule.id {
                                        selectedSchedule = nil
                                    }
                                }
                            }
                        }
                }
            }
            .navigationTitle("Schedules")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        coordinator.createNewSchedule()
                    } label: {
                        Label("Add Schedule", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selected = selectedSchedule {
                ScheduleEditorView(schedule: selected)
                    .environment(coordinator)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No schedule selected")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Click + to create a new schedule")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: Bindable(coordinator).showingScheduleEditor) {
            if let schedule = coordinator.editingSchedule {
                ScheduleEditorView(schedule: schedule)
                    .environment(coordinator)
                    .frame(minWidth: 450, minHeight: 500)
            }
        }
        .onAppear {
            Task { await coordinator.loadSchedules() }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct ScheduleRow: View {
    let schedule: WakeSchedule

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.label)
                    .font(.headline)

                HStack(spacing: 6) {
                    Text(schedule.targetTime)
                    Text("·")
                    Text(daysDescription)
                    if schedule.requiresACPower {
                        Text("· AC Required")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Circle()
                .fill(schedule.isEnabled ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }

    private var daysDescription: String {
        if schedule.repeatDays.count == 7 {
            return "Every day"
        } else if schedule.repeatDays.isEmpty {
            return "Never"
        } else {
            let sorted = schedule.repeatDays.sorted { $0.rawValue < $1.rawValue }
            return sorted.map(\.shortName).joined(separator: ", ")
        }
    }
}
