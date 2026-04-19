import SwiftUI

struct DiagnosticsView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Diagnostics")
                    .font(.title2)
                    .padding(.bottom, 4)

                GroupBox("System State") {
                    VStack(alignment: .leading, spacing: 8) {
                        diagnosticRow("Power Source", value: coordinator.runtimeState.powerSource.rawValue)
                        diagnosticRow("Enforcement", value: coordinator.runtimeState.enforcementState.displayName)
                        diagnosticRow("Assertion Active", value: coordinator.runtimeState.activeAssertion ? "Yes" : "No")

                        if let next = coordinator.runtimeState.nextTrigger {
                            diagnosticRow("Next Trigger", value: next.formatted())
                        }

                        if let sleep = coordinator.runtimeState.lastSleepAt {
                            diagnosticRow("Last Sleep", value: sleep.formatted())
                        }
                        if let wake = coordinator.runtimeState.lastWakeAt {
                            diagnosticRow("Last Wake", value: wake.formatted())
                        }

                        if let error = coordinator.runtimeState.lastFailureReason {
                            diagnosticRow("Last Error", value: error)
                        }
                    }
                    .padding(8)
                }

                GroupBox("Schedules") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(coordinator.schedules.count) total, \(coordinator.schedules.filter(\.isEnabled).count) enabled")
                            .font(.subheadline)
                    }
                    .padding(8)
                }
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
    }

    private func diagnosticRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .foregroundStyle(.secondary)
            Text(value)
        }
        .font(.system(.body, design: .monospaced))
    }
}
