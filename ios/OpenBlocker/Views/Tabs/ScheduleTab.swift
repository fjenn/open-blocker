import SwiftUI

struct ScheduleTab: View {
    @ObservedObject var appState = AppState.shared
    @State private var editor: Editor?
    @AppStorage(DailyLimits.storageKey) private var limitsEnabled = false
    
    /// What the sheet edits. One item, so the sheet never opens with a stale kind.
    private struct Editor: Identifiable {
        let id = UUID()
        let schedule: BlockSchedule?
        let isLimit: Bool
    }
    
    private var timed: [BlockSchedule] { appState.schedules.filter { $0.dailyLimitMinutes == nil } }
    private var limits: [BlockSchedule] { appState.schedules.filter { $0.dailyLimitMinutes != nil } }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabScreen(title: "Schedules") {
                if appState.schedules.isEmpty {
                    EmptyStateView(
                        systemImage: "calendar",
                        title: "No schedules yet",
                        message: limitsEnabled
                            ? "Block at set times, or after a daily allowance is used up."
                            : "Block automatically at set times, every day or only on the days you pick."
                    )
                    .frame(minHeight: 380)
                } else {
                    VStack(alignment: .leading, spacing: Space.s) {
                        // Headers only when both kinds are on screen.
                        let headed = !timed.isEmpty && !limits.isEmpty
                        if headed { sectionHeader("Schedules", first: true) }
                        ForEach(timed) { schedule in
                            ScheduleCard(schedule: schedule) { edit(schedule) }
                        }
                        if headed { sectionHeader("Daily limits", first: false) }
                        ForEach(limits) { schedule in
                            ScheduleCard(schedule: schedule) { edit(schedule, limit: true) }
                        }
                    }
                    // Room for the floating create button.
                    Spacer().frame(height: 120)
                }
            }
            
            createButton
                .padding(.bottom, Space.l)
        }
        .accessibilityIdentifier(AccessibilityID.scheduleRoot)
        .sheet(item: $editor) { editor in
            ScheduleEditScreen(schedule: editor.schedule, isLimit: editor.isLimit)
        }
    }
    
    /// One create button. With daily limits on it asks which kind.
    @ViewBuilder
    private var createButton: some View {
        if limitsEnabled {
            Menu {
                Button { edit(nil) } label: { Label("Schedule", systemImage: "calendar") }
                Button { edit(nil, limit: true) } label: { Label("Daily limit", systemImage: "hourglass") }
            } label: {
                CreateButtonLabel(caption: "Create")
            }
            .accessibilityLabel("Create")
            .accessibilityIdentifier("create-schedule-or-limit")
        } else {
            Button { edit(nil) } label: { CreateButtonLabel(caption: "Create schedule") }
                .buttonStyle(PressScaleStyle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Create schedule")
                .accessibilityAddTraits(.isButton)
        }
    }
    
    private func sectionHeader(_ title: String, first: Bool) -> some View {
        Text(title)
            .textStyle(.subhead, weight: .semibold)
            .foregroundColor(Color.inkSecondary)
            .padding(.horizontal, Space.xxs)
            .padding(.top, first ? 0 : Space.m)
    }
    
    private func edit(_ schedule: BlockSchedule?, limit: Bool = false) {
        editor = Editor(schedule: schedule, isLimit: limit)
    }
}

/// Caption over a round plus button.
private struct CreateButtonLabel: View {
    let caption: String
    
    var body: some View {
        VStack(spacing: Space.s) {
            Text(caption)
                .textStyle(.footnote)
                .foregroundColor(Color.inkSecondary)
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(Color.ink)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(Color.surfaceRaised)
                        .shadow(color: Color.floatShadow, radius: 14, y: 6)
                )
        }
        .contentShape(Rectangle())
    }
}

struct ScheduleCard: View {
    let schedule: BlockSchedule
    var onEdit: () -> Void
    @ObservedObject var appState = AppState.shared
    @State private var deniedPermission: Permission?
    
    var body: some View {
        HStack(alignment: .center, spacing: Space.s) {
            VStack(alignment: .leading, spacing: 3) {
                Text(schedule.name)
                    .textStyle(.body, weight: .semibold)
                    .foregroundColor(Color.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .textStyle(.subhead)
                    .foregroundColor(Color.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(modeLabel)
                    .textStyle(.subhead)
                    .foregroundColor(Color.inkSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Space.xs)
            Toggle(schedule.name, isOn: Binding(
                get: { schedule.isOn && schedule.modeID != nil },
                set: { on in
                    var updated = schedule
                    updated.isOn = on
                    guard on else { return appState.updateSchedule(updated) }
                    Permissions.whenGranted(.screenTime, denied: $deniedPermission) {
                        appState.updateSchedule(updated)
                    }
                }
            ))
            .labelsHidden()
            .tint(Color.accent)
            .disabled(schedule.modeID == nil)
        }
        .padding(.horizontal, Space.m)
        .padding(.vertical, 14)
        .background(CardBackground(raised: schedule.isOn && schedule.modeID != nil))
        .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .onTapGesture(perform: onEdit)
        .accessibilityAction(named: "Edit", onEdit)
        .permissionSheet($deniedPermission)
    }
    
    private var subtitle: String {
        guard let limit = schedule.dailyLimitMinutes else {
            return "\(schedule.timeRangeString) · \(schedule.daysString)"
        }
        let allDay = schedule.startMinute == 0 && schedule.endMinute == 1439
        let hours = allDay ? "" : " · \(schedule.timeRangeString)"
        return "\(BlockSchedule.limitText(limit)) a day\(hours) · \(schedule.daysString)"
    }
    
    private var modeLabel: String {
        if let id = schedule.modeID, let mode = appState.modes.first(where: { $0.id == id }) {
            if schedule.dailyLimitMinutes != nil, schedule.effectiveLimit(mode: mode) == nil {
                return "Mode: \(mode.name) · choose what counts"
            }
            return "Mode: \(mode.name)"
        }
        return "Choose a mode to turn it on"
    }
}
