import SwiftUI

@main
struct AwakeUtilityApp: App {
    @State private var appCoordinator = AppCoordinator()

    var body: some Scene {
        MenuBarExtra {
            StartupView()
                .environment(appCoordinator)
        } label: {
            Label {
                Text("Awake Utility")
            } icon: {
                Image(systemName: appCoordinator.iconName)
            }
        }
        .menuBarExtraStyle(.window)

        Window("Schedule Editor", id: "schedule-editor") {
            ScheduleListView()
                .environment(appCoordinator)
        }
        .windowStyle(.automatic)

        Window("Diagnostics", id: "diagnostics") {
            DiagnosticsView()
                .environment(appCoordinator)
        }
        .windowStyle(.automatic)
    }
}

private struct StartupView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        MenuBarView()
            .task { await coordinator.start() }
    }
}
