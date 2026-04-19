import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsStore()

    var body: some View {
        Form {
            GroupBox("Defaults for New Schedules") {
                VStack(spacing: 12) {
                    Stepper("Lead time: \(settings.defaultLeadMinutes) min", value: $settings.defaultLeadMinutes, in: 1...60)
                    Stepper("Hold time: \(settings.defaultHoldMinutes) min", value: $settings.defaultHoldMinutes, in: 0...60)
                    Toggle("Require AC Power by default", isOn: $settings.defaultRequiresAC)
                }
                .padding(8)
            }

            GroupBox("App") {
                VStack(spacing: 12) {
                    Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                }
                .padding(8)
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 250)
        .onDisappear {
            settings.save()
        }
    }
}
