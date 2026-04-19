import SwiftUI

struct MenuBarView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Awake Utility")
                .font(.headline)
                .padding(.bottom, 4)

            Divider()

            statusSection
            Divider()
            quickActions
            Divider()
            settings
        }
        .padding()
        .frame(width: 280)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: coordinator.iconName)
                Text(coordinator.runtimeState.enforcementState.displayName)
                    .font(.subheadline)
            }

            if let schedule = coordinator.enforcedSchedule {
                Text(schedule.windowDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: coordinator.runtimeState.powerSource == .ac ? "bolt.fill" : "battery.0")
                Text(coordinator.runtimeState.powerSource == .ac ? "On AC Power" : "On Battery")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var quickActions: some View {
        Group {
            Button {
                openWindow(id: "schedule-editor")
            } label: {
                Label("Schedules...", systemImage: "calendar")
            }

            Button {
                openWindow(id: "diagnostics")
            } label: {
                Label("Diagnostics...", systemImage: "info.circle")
            }
        }
    }

    private var settings: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("Quit")
        }
    }
}
