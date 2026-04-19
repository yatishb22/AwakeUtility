import SwiftUI

struct ScheduleEditorView: View {
    @Environment(AppCoordinator.self) private var coordinator
    let schedule: WakeSchedule

    @State private var label: String = ""
    @State private var hour: Int = 8
    @State private var minute: Int = 0
    @State private var selectedDays: Set<Weekday> = []
    @State private var leadMinutes: Int = 15
    @State private var holdMinutes: Int = 15
    @State private var requiresAC: Bool = true
    @State private var validationMessage: String?
    @State private var targetTime: Date = Date()

    var body: some View {
        Form {
            GroupBox("Schedule") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Label", text: $label)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Text("Time:")
                        DatePicker("", selection: $targetTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

                    DayPicker(selectedDays: $selectedDays)
                }
                .padding(8)
            }

            GroupBox("Advanced") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Stepper("Lead time: \(leadMinutes) min", value: $leadMinutes, in: 1...60)
                    }
                    .help("How long before the target time to start keeping the Mac awake")

                    HStack {
                        Stepper("Hold time: \(holdMinutes) min", value: $holdMinutes, in: 0...60)
                    }
                    .help("How long after the target time to keep the Mac awake")

                    Toggle("Require AC Power", isOn: $requiresAC)
                        .help("Only enforce awake state when connected to external power")
                }
                .padding(8)
            }

            if let message = validationMessage {
                Text(message)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .onAppear { loadSchedule() }
        .onChange(of: targetTime) { _, newDate in
            hour = Calendar.current.component(.hour, from: newDate)
            minute = Calendar.current.component(.minute, from: newDate)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    coordinator.dismissEditor()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSchedule()
                }
                .disabled(!isValid)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var isValid: Bool {
        label.trimmingCharacters(in: .whitespaces).isEmpty == false
        && !selectedDays.isEmpty
        && leadMinutes >= 1
    }

    private func loadSchedule() {
        label = schedule.label
        hour = schedule.hour
        minute = schedule.minute
        targetTime = Calendar.current.date(bySettingHour: schedule.hour, minute: schedule.minute, second: 0, of: Date()) ?? Date()
        selectedDays = schedule.repeatDays
        leadMinutes = schedule.leadMinutes
        holdMinutes = schedule.holdMinutes
        requiresAC = schedule.requiresACPower
    }

    private func saveSchedule() {
        guard isValid else {
            validationMessage = "Please provide a label and at least one day."
            return
        }

        var updated = schedule
        updated.label = label.trimmingCharacters(in: .whitespaces)
        updated.hour = hour
        updated.minute = minute
        updated.repeatDays = selectedDays
        updated.leadMinutes = leadMinutes
        updated.holdMinutes = holdMinutes
        updated.requiresACPower = requiresAC

        Task {
            await coordinator.saveSchedule(updated)
            coordinator.dismissEditor()
        }
    }
}

struct DayPicker: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repeat days:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Toggle(day.shortName, isOn: dayBinding(for: day))
                        .toggleStyle(.checkbox)
                        .font(.caption)
                        .fixedSize()
                }
            }
        }
    }

    private func dayBinding(for day: Weekday) -> Binding<Bool> {
        Binding(
            get: { selectedDays.contains(day) },
            set: { isSelected in
                if isSelected {
                    selectedDays.insert(day)
                } else {
                    selectedDays.remove(day)
                }
            }
        )
    }
}
