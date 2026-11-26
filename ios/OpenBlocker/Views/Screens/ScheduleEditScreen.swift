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
    @State private var limitCounts: FamilyActivitySelection
    @State private var pickingLimitCounts = false
    @State private var allDay: Bool
    @State private var confirmingDelete = false
    @State private var nameNeedsAttention = false
    @State private var nameShake = 0
    @State private var countsNeedAttention = false
    @State private var countsShake = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var deniedPermission: Permission?
    
    init(schedule: BlockSchedule? = nil, isLimit: Bool = false) {
        self.schedule = schedule
        let isLimit = isLimit || schedule?.dailyLimitMinutes != nil
        self.isLimit = isLimit
        _allDay = State(initialValue: schedule.map { $0.startMinute == 0 && $0.endMinute == 1439 } ?? true)
        _name = State(initialValue: schedule?.name ?? "")
        _modeID = State(initialValue: schedule?.modeID ?? AppState.shared.activeMode?.id)
        _start = State(initialValue: Self.date(forMinute: schedule?.startMinute ?? 9 * 60))
        _end = State(initialValue: Self.date(forMinute: schedule?.endMinute ?? 17 * 60))
        _days = State(initialValue: schedule?.weekdays ?? (isLimit ? Set(1...7) : [2, 3, 4, 5, 6]))
        _isOn = State(initialValue: schedule?.isOn ?? true)
        _endsOnKey = State(initialValue: schedule?.endsOnKey ?? false)
        _limit = State(initialValue: schedule?.dailyLimitMinutes ?? (isLimit ? 60 : nil))
        _limitCounts = State(initialValue: schedule?.limitCounts ?? FamilyActivitySelection())
    }
    
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var selectedMode: BlockMode? {
        appState.modes.first { $0.id == modeID }
    }
    
    /// Allow-only modes have no list to count, so the user picks one.
    private var needsLimitCounts: Bool {
        isLimit && selectedMode?.kind == .allowOnly
    }
    
    private var noun: String { isLimit ? "limit" : "schedule" }
    
    private var limitCountsEmpty: Bool {
        BlockSchedule.encodeLimitCounts(limitCounts) == nil
    }
    
    private var limitCountsSummary: String {
        let n = limitCounts.applicationTokens.count, c = limitCounts.categoryTokens.count
        if n == 0 && c == 0 { return limitCountsEmpty ? "Choose apps" : "Websites" }
        return [c > 0 ? "\(c) categor\(c == 1 ? "y" : "ies")" : nil, n > 0 ? "\(n) app\(n == 1 ? "" : "s")" : nil]
            .compactMap { $0 }.joined(separator: ", ")
    }
    
    /// A missing name or what-counts pick is shown on tap (shake + red), like key setup.
    private var canSave: Bool {
        modeID != nil && !days.isEmpty
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
                        if needsLimitCounts {
                            HairlineDivider()
                            FormRow(label: "Time in") {
                                Button {
                                    pickingLimitCounts = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(limitCountsSummary)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(Color.inkTertiary)
                                    }
                                }
                                .accessibilityIdentifier("limit-counts")
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.group, style: .continuous)
                            .stroke(countsNeedAttention ? Color.danger : Color.clear, lineWidth: 1.5)
                    )
                    .shake(trigger: countsShake, reducedMotion: reduceMotion)
                    .onChange(of: limitCounts) { _ in
                        if countsNeedAttention { countsNeedAttention = false }
                    }
                    if countsNeedAttention {
                        Text("Choose which apps' time uses up the limit")
                            .textStyle(.footnote)
                            .foregroundColor(Color.danger)
                            .padding(.leading, Space.xxs)
                    }
                    if let limit, isLimit {
                        footnote(limitFootnote(limit))
                    }
                    
                    if isLimit {
                        SettingsGroup {
                            ToggleRow(title: "All day", isOn: $allDay.animation(Motion.quick))
                            if !allDay {
                                HairlineDivider()
                                timeRow("From", selection: $start)
                                HairlineDivider()
                                timeRow("To", selection: $end)
                            }
                        }
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
        .familyActivityPicker(isPresented: $pickingLimitCounts, selection: $limitCounts)
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
    private func limitFootnote(_ limit: Int) -> String {
        let amount = BlockSchedule.limitText(limit)
        if selectedMode?.kind == .allowOnly {
            return "This mode only allows a few apps, so pick whose time counts under Time in. After \(amount) a day there, the mode turns on until the day ends or you tap your key. To count all phone use, choose every category."
        }
        return "After \(amount) a day in the apps and sites this mode blocks, they are blocked until the day ends or you tap your key."
    }
    
    private func save() {
        if trimmedName.isEmpty {
            nameNeedsAttention = true
            nameShake += 1
            return attentionFeedback("Add a name")
        }
        if needsLimitCounts && limitCountsEmpty {
            countsNeedAttention = true
            countsShake += 1
            return attentionFeedback("Choose which apps' time uses up the limit")
        }
        guard isOn else { return commit() }
        Permissions.whenGranted(.screenTime, denied: $deniedPermission, perform: commit)
    }
    
    private func attentionFeedback(_ message: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    private func commit() {
        let fullDay = isLimit && allDay
        let startMinute = fullDay ? 0 : Self.minute(of: start)
        let endMinute = fullDay ? 1439 : Self.minute(of: end)
        let endsOnKey = isLimit ? false : endsOnKey
        if var updated = schedule {
            updated.name = trimmedName
            updated.modeID = modeID
            updated.startMinute = startMinute
            updated.endMinute = endMinute
            updated.weekdays = days
            updated.isOn = isOn
            updated.endsOnKey = endsOnKey
            updated.dailyLimitMinutes = isLimit ? limit : nil
            updated.limitCounts = needsLimitCounts ? limitCounts : FamilyActivitySelection()
            appState.updateSchedule(updated)
        } else {
            appState.addSchedule(BlockSchedule(
                name: trimmedName,
                weekdays: days,
                startMinute: startMinute,
                endMinute: endMinute,
                modeID: modeID,
                isOn: isOn,
                endsOnKey: endsOnKey,
                dailyLimitMinutes: isLimit ? limit : nil,
                limitCountsData: needsLimitCounts ? BlockSchedule.encodeLimitCounts(limitCounts) : nil
            ))
        }
        dismiss()
    }
}
