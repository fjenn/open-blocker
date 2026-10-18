import SwiftUI

struct ScheduleEditScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appState = AppState.shared
    
    let schedule: BlockSchedule?
    
    @State private var name: String
    @State private var modeID: UUID?
    @State private var start: Date
    @State private var end: Date
    @State private var days: Set<Int>
    @State private var isOn: Bool
    @State private var endsOnKey: Bool
    @State private var confirmingDelete = false
    @State private var deniedPermission: Permission?
    
    init(schedule: BlockSchedule? = nil) {
        self.schedule = schedule
        _name = State(initialValue: schedule?.name ?? "")
        _modeID = State(initialValue: schedule?.modeID ?? AppState.shared.activeMode?.id)
        _start = State(initialValue: Self.date(forMinute: schedule?.startMinute ?? 9 * 60))
        _end = State(initialValue: Self.date(forMinute: schedule?.endMinute ?? 17 * 60))
        _days = State(initialValue: schedule?.weekdays ?? [2, 3, 4, 5, 6])
        _isOn = State(initialValue: schedule?.isOn ?? true)
        _endsOnKey = State(initialValue: schedule?.endsOnKey ?? false)
    }
    
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var canSave: Bool {
        !trimmedName.isEmpty && modeID != nil && !days.isEmpty
    }
    
    var body: some View {
        SheetScaffold(
            title: schedule == nil ? "Add schedule" : "Edit schedule",
            trailing: SheetAction(systemImage: "xmark", accessibilityLabel: "Cancel") { dismiss() },
            primary: SheetAction(title: "Save schedule", isEnabled: canSave) { save() }
        ) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s) {
                    SettingsGroup {
                        FormTextField(label: "Name", placeholder: "e.g. Work, Evenings", text: $name)
                    }
                    
                    SettingsGroup {
                        timeRow("Starts", selection: $start)
                        HairlineDivider()
                        FormRow(label: "Ends") {
                            Menu {
                                Button("At a set time") { withAnimation(Motion.quick) { endsOnKey = false } }
                                Button("Until I tap my key") { withAnimation(Motion.quick) { endsOnKey = true } }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(endsOnKey ? "Until I tap my key" : "At a set time")
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Color.inkTertiary)
                                }
                            }
                            .accessibilityIdentifier("schedule-ends-mode")
                        }
                        if !endsOnKey {
                            HairlineDivider()
                            timeRow("End time", selection: $end)
                        }
                    }
                    if endsOnKey {
                        Text("The block stays on until you tap your key.")
                            .textStyle(.footnote)
                            .foregroundColor(Color.inkSecondary)
                            .padding(.horizontal, Space.xxs)
                    }
                    
                    SettingsGroup {
                        Menu {
                            ForEach(appState.modes) { mode in
                                Button(mode.name) { modeID = mode.id }
                            }
                        } label: {
                            FormRow(label: "Mode") {
                                HStack(spacing: 4) {
                                    Text(selectedModeName)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Color.inkTertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    HStack {
                        Text("Repeat")
                            .textStyle(.subhead)
                            .foregroundColor(Color.inkSecondary)
                        Spacer()
                        Text(days.isEmpty ? "Pick at least one day" : repeatSummary)
                            .textStyle(.subhead)
                            .foregroundColor(days.isEmpty ? Color.danger : Color.inkSecondary)
                    }
                    .padding(.horizontal, Space.xxs)
                    .padding(.top, Space.s)
                    
                    HStack(spacing: 0) {
                        ForEach(Array(Self.dayOrder.enumerated()), id: \.offset) { _, day in
                            dayToggle(day)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    if schedule != nil {
                        Button(role: .destructive) { confirmingDelete = true } label: {
                            Text("Delete schedule")
                                .textStyle(.subhead, weight: .semibold)
                                .foregroundColor(Color.danger)
                                .frame(maxWidth: .infinity, minHeight: Metrics.compactButtonHeight)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, Space.l)
                    }
                }
                .padding(.horizontal, Space.margin)
                .padding(.top, Space.xxs)
                .padding(.bottom, Space.l)
            }
        }
        .confirmationDialog("Delete this schedule?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let schedule { appState.deleteSchedule(schedule) }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .permissionSheet($deniedPermission)
    }
    
    private var repeatSummary: String {
        switch days.count {
        case 7: return "Every day"
        default:
            if days == [2, 3, 4, 5, 6] { return "Weekdays" }
            if days == [1, 7] { return "Weekends" }
            return "\(days.count) days a week"
        }
    }
    
    /// Monday-first display, Calendar weekday numbers (1 = Sunday).
    private static let dayOrder: [(label: String, weekday: Int)] = [
        ("M", 2), ("T", 3), ("W", 4), ("T", 5), ("F", 6), ("S", 7), ("S", 1)
    ]
    
    private var selectedModeName: String {
        appState.modes.first { $0.id == modeID }?.name ?? "Choose a mode"
    }
    
    private func timeRow(_ title: String, selection: Binding<Date>) -> some View {
        FormRow(label: title) {
            DatePicker(title, selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Color.ink)
        }
    }
    
    private func dayToggle(_ day: (label: String, weekday: Int)) -> some View {
        let on = days.contains(day.weekday)
        return Button {
            withAnimation(Motion.quick) {
                if on { days.remove(day.weekday) } else { days.insert(day.weekday) }
            }
        } label: {
            Text(day.label)
                .textStyle(.subhead, weight: .semibold)
                .foregroundColor(on ? Color.inkInverse : Color.inkSecondary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(on ? Color.ink : Color.surface)
                        .shadow(color: Color.floatShadow.opacity(on ? 0 : 0.5), radius: 4, y: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
    
    private static func date(forMinute minute: Int) -> Date {
        Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: Date()) ?? Date()
    }
    
    private static func minute(of date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }
    
    /// A schedule that's on blocks through Screen Time, so ask for it first.
    private func save() {
        guard isOn else { return commit() }
        Permissions.whenGranted(.screenTime, denied: $deniedPermission, perform: commit)
    }
    
    private func commit() {
        let startMinute = Self.minute(of: start)
        let endMinute = Self.minute(of: end)
        if var updated = schedule {
            updated.name = trimmedName
            updated.modeID = modeID
            updated.startMinute = startMinute
            updated.endMinute = endMinute
            updated.weekdays = days
            updated.isOn = isOn
            updated.endsOnKey = endsOnKey
            appState.updateSchedule(updated)
        } else {
            appState.addSchedule(BlockSchedule(
                name: trimmedName,
                weekdays: days,
                startMinute: startMinute,
                endMinute: endMinute,
                modeID: modeID,
                isOn: isOn,
                endsOnKey: endsOnKey
            ))
        }
        dismiss()
    }
}
