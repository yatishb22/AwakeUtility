import SwiftUI

struct ScheduleEditorView: View {
    @Environment(AppCoordinator.self) private var coordinator
    let schedule: WakeSchedule

    @State private var label: String = ""
    @State private var selectedDays: Set<Weekday> = []
    @State private var requiresAC: Bool = true
    @State private var validationMessage: String?
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()

    var body: some View {
        Form {
            GroupBox("Schedule") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Label", text: $label)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Text("Start:")
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

                    HStack {
                        Text("End:")
                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

                    DayPicker(selectedDays: $selectedDays)
                }
                .padding(8)
            }

            GroupBox("Advanced") {
                VStack(alignment: .leading, spacing: 12) {
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
    }

    private func loadSchedule() {
        label = schedule.label
        let calendar = Calendar.current
        startTime = calendar.date(bySettingHour: schedule.startHour, minute: schedule.startMinute, second: 0, of: Date()) ?? Date()
        endTime = calendar.date(bySettingHour: schedule.endHour, minute: schedule.endMinute, second: 0, of: Date()) ?? Date()
        selectedDays = schedule.repeatDays
        requiresAC = schedule.requiresACPower
    }

    private func saveSchedule() {
        guard isValid else {
            validationMessage = "Please provide a label and at least one day."
            return
        }

        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startTime)
        let startMinute = calendar.component(.minute, from: startTime)
        let endHour = calendar.component(.hour, from: endTime)
        let endMinute = calendar.component(.minute, from: endTime)

        var updated = schedule
        updated.label = label.trimmingCharacters(in: .whitespaces)
        updated.startHour = startHour
        updated.startMinute = startMinute
        updated.endHour = endHour
        updated.endMinute = endMinute
        updated.repeatDays = selectedDays
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
