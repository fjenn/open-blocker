import SwiftUI
import FamilyControls

struct ScheduleEditScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appState = AppState.shared
    
    let schedule: BlockSchedule?
    /// A limit ("2 hr of these apps a day") rather than a timed schedule.
    let isLimit: Bool
    
    @State private var name: String
    @State private var modeID: UUID?
    @State private var start: Date
    @State private var end: Date
    @State private var days: Set<Int>
    @State private var isOn: Bool
    @State private var endsOnKey: Bool
    @State private var limit: Int?
    @State private var limitApps: FamilyActivitySelection
    @State private var pickingLimitApps = false
    @State private var confirmingDelete = false
    @State private var nameNeedsAttention = false
    @State private var nameShake = 0
    @State private var appsNeedAttention = false
    @State private var appsShake = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var deniedPermission: Permission?
    
    init(schedule: BlockSchedule? = nil, isLimit: Bool = false) {
        self.schedule = schedule
        let isLimit = isLimit || schedule?.dailyLimitMinutes != nil
        self.isLimit = isLimit
        _name = State(initialValue: schedule?.name ?? "")
        _modeID = State(initialValue: schedule?.modeID ?? AppState.shared.activeMode?.id)
        _start = State(initialValue: Self.date(forMinute: schedule?.startMinute ?? 9 * 60))
        _end = State(initialValue: Self.date(forMinute: schedule?.endMinute ?? 17 * 60))
        _days = State(initialValue: schedule?.weekdays ?? (isLimit ? Set(1...7) : [2, 3, 4, 5, 6]))
        _isOn = State(initialValue: schedule?.isOn ?? true)
        _endsOnKey = State(initialValue: schedule?.endsOnKey ?? false)
        _limit = State(initialValue: schedule?.dailyLimitMinutes ?? (isLimit ? 60 : nil))
        _limitApps = State(initialValue: schedule?.limitApps ?? FamilyActivitySelection())
    }
    
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var noun: String { isLimit ? "limit" : "schedule" }
    
    private var limitAppsEmpty: Bool {
        BlockSchedule.encodeLimitApps(limitApps) == nil
    }
    
    private var limitAppsSummary: String {
        BlockSchedule.summary(of: limitApps) ?? "Choose apps"
    }
    
    /// A missing name or app pick is shown on tap (shake + red), like key setup.
    private var canSave: Bool {
        (isLimit || modeID != nil) && !days.isEmpty
    }
    
    var body: some View {
        SheetScaffold(
            title: schedule == nil ? "Add \(noun)" : "Edit \(noun)",
            trailing: SheetAction(systemImage: "xmark", accessibilityLabel: "Cancel") { dismiss() },
            primary: SheetAction(title: "Save \(noun)", isEnabled: canSave) { save() }
        ) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s) {
                    SettingsGroup {
                        FormTextField(label: "Name", placeholder: isLimit ? "e.g. Social media" : "e.g. Work, Evenings", text: $name)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.group, style: .continuous)
                            .stroke(nameNeedsAttention ? Color.danger : Color.clear, lineWidth: 1.5)
                    )
                    .shake(trigger: nameShake, reducedMotion: reduceMotion)
                    .onChange(of: name) { _ in
                        if nameNeedsAttention { nameNeedsAttention = false }
                    }
                    if nameNeedsAttention {
                        Text("Add a name")
                            .textStyle(.footnote)
                            .foregroundColor(Color.danger)
                            .padding(.leading, Space.xxs)
                    }
                    
                    if isLimit {
                        limitGroup
                    } else {
                        timesGroup
                        if endsOnKey {
                            footnote("The block stays on until you tap your key.")
                        }
                    }
                    
                    if isLimit {
                        appsGroup
                    } else {
                        modeGroup
                    }
                    if let limit, isLimit {
                        footnote("After \(BlockSchedule.limitText(limit)) a day in these apps, they're blocked until midnight or until you tap your key.")
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
                            Text("Delete \(noun)")
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
        .confirmationDialog("Delete this \(noun)?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let schedule { appState.deleteSchedule(schedule) }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .permissionSheet($deniedPermission)
        .familyActivityPicker(isPresented: $pickingLimitApps, selection: $limitApps)
    }
    
    private var timesGroup: some View {
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
    }
    
    private var modeGroup: some View {
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
    }
    
    /// A limit's own apps: counted, then blocked once the time is used up.
    @ViewBuilder
    private var appsGroup: some View {
        SettingsGroup {
            FormRow(label: "Apps") {
                Button {
                    pickingLimitApps = true
                } label: {
                    HStack(spacing: 4) {
                        Text(limitAppsSummary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.inkTertiary)
                    }
                }
                .accessibilityIdentifier("limit-apps")
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Radius.group, style: .continuous)
                .stroke(appsNeedAttention ? Color.danger : Color.clear, lineWidth: 1.5)
        )
        .shake(trigger: appsShake, reducedMotion: reduceMotion)
        .onChange(of: limitApps) { _ in
            if appsNeedAttention { appsNeedAttention = false }
        }
        if appsNeedAttention {
            Text("Choose the apps this limit counts")
                .textStyle(.footnote)
                .foregroundColor(Color.danger)
                .padding(.leading, Space.xxs)
        }
    }
    
    private var limitGroup: some View {
        SettingsGroup {
            FormRow(label: "Per day") {
                Menu {
                    ForEach(BlockSchedule.limitChoices, id: \.self) { minutes in
                        Button(BlockSchedule.limitText(minutes)) {
                            withAnimation(Motion.quick) { limit = minutes }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(BlockSchedule.limitText(limit ?? 60))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.inkTertiary)
                    }
                }
                .accessibilityIdentifier("limit-amount")
            }
        }
    }
    
    private func footnote(_ text: String) -> some View {
        Text(text)
            .textStyle(.footnote)
            .foregroundColor(Color.inkSecondary)
            .padding(.horizontal, Space.xxs)
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
        if trimmedName.isEmpty {
            nameNeedsAttention = true
            nameShake += 1
            return attentionFeedback("Add a name")
        }
        if isLimit && limitAppsEmpty {
            appsNeedAttention = true
            appsShake += 1
            return attentionFeedback("Choose the apps this limit counts")
        }
        guard isOn else { return commit() }
        Permissions.whenGranted(.screenTime, denied: $deniedPermission, perform: commit)
    }
    
    private func attentionFeedback(_ message: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    private func commit() {
        // A limit always covers the whole day and starts fresh at midnight.
        let startMinute = isLimit ? 0 : Self.minute(of: start)
        let endMinute = isLimit ? 1439 : Self.minute(of: end)
        let endsOnKey = isLimit ? false : endsOnKey
        let id = schedule?.id ?? UUID()
        // A limit blocks its own apps, so it is its own mode.
        let modeID = isLimit ? id : modeID
        let appsData = isLimit ? BlockSchedule.encodeLimitApps(limitApps) : nil
        if var updated = schedule {
            updated.name = trimmedName
            updated.modeID = modeID
            updated.startMinute = startMinute
            updated.endMinute = endMinute
            updated.weekdays = days
            updated.isOn = isOn
            updated.endsOnKey = endsOnKey
            updated.dailyLimitMinutes = isLimit ? limit : nil
            updated.limitAppsData = appsData
            appState.updateSchedule(updated)
        } else {
            appState.addSchedule(BlockSchedule(
                id: id,
                name: trimmedName,
                weekdays: days,
                startMinute: startMinute,
                endMinute: endMinute,
                modeID: modeID,
                isOn: isOn,
                endsOnKey: endsOnKey,
                dailyLimitMinutes: isLimit ? limit : nil,
                limitAppsData: appsData
            ))
        }
        dismiss()
    }
}
