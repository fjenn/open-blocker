import SwiftUI

struct ScheduleTab: View {
    @ObservedObject var appState = AppState.shared
    @State private var showingEditor = false
    @State private var editing: BlockSchedule?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabScreen(title: "Schedules") {
                if appState.schedules.isEmpty {
                    EmptyStateView(
                        systemImage: "calendar",
                        title: "No schedules yet",
                        message: "Block automatically at set times, every day or only on the days you pick."
                    )
                    .frame(minHeight: 380)
                } else {
                    VStack(spacing: Space.s) {
                        ForEach(appState.schedules) { schedule in
                            ScheduleCard(schedule: schedule) { edit(schedule) }
                        }
                    }
                    // Room for the floating create button.
                    Spacer().frame(height: 120)
                }
            }
            
            CreateScheduleButton { edit(nil) }
                .padding(.bottom, Space.l)
        }
        .accessibilityIdentifier(AccessibilityID.scheduleRoot)
        .sheet(isPresented: $showingEditor) {
            ScheduleEditScreen(schedule: editing)
        }
    }
    
    private func edit(_ schedule: BlockSchedule?) {
        editing = schedule
        showingEditor = true
    }
}

/// Floating "Create schedule" caption over a round plus button.
private struct CreateScheduleButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Space.s) {
                Text("Create schedule")
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
        .buttonStyle(PressScaleStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Create schedule")
        .accessibilityAddTraits(.isButton)
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
                Text("\(schedule.timeRangeString) · \(schedule.daysString)")
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
    
    private var modeLabel: String {
        if let id = schedule.modeID, let mode = appState.modes.first(where: { $0.id == id }) {
            return "Mode: \(mode.name)"
        }
        return "Choose a mode to turn it on"
    }
}
