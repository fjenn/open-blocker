// Schedule tab - simplified for new architecture

import SwiftUI

struct ScheduleTab: View {
    @ObservedObject var appState = AppState.shared
    @State private var showingEditor = false
    
    var body: some View {
        ZStack {
            Color.brickCanvas
                .ignoresSafeArea()
            
            VStack {
                if appState.schedules.isEmpty {
                    emptyState
                } else {
                    schedulesList
                }
            }
            .accessibilityIdentifier(AccessibilityID.scheduleRoot)
        }
        .sheet(isPresented: $showingEditor) {
            ScheduleEditScreen()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("No schedules yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color.brickInk)
            
            Text("Block apps automatically at set times.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.brickMuted)
                .multilineTextAlignment(.center)
            
            Button(action: { showingEditor = true }) {
                VStack(spacing: 8) {
                    Circle()
                        .fill(Color.brickCard)
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 22))
                                .foregroundColor(Color.brickInk)
                        )
                    
                    Text("Create schedule")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.brickMuted)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var schedulesList: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Schedules")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.brickInk)
                    .padding(.top, 84)
                
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    ForEach(appState.schedules) { schedule in
                        ScheduleCard(schedule: schedule)
                    }
                }
                .padding(.horizontal, 24)
                
                Button(action: { showingEditor = true }) {
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.brickCard)
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.brickInk)
                            )
                        
                        Text("Create schedule")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.brickMuted)
                    }
                }
                .padding(.top, 50)
            }
            .padding(.bottom, BrickLayout.tabScrollInset)
        }
    }
}

struct ScheduleCard: View {
    let schedule: BlockSchedule
    @ObservedObject var appState = AppState.shared
    
    private let chipDays: [(label: String, weekday: Int)] = [
        ("M", 2), ("T", 3), ("W", 4), ("T", 5), ("F", 6), ("S", 7), ("S", 1)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Text(schedule.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color.brickInk)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Toggle("", isOn: Binding(
                    get: { schedule.isOn && schedule.modeID != nil },
                    set: { newValue in
                        var updated = schedule
                        updated.isOn = newValue
                        appState.updateSchedule(updated)
                    }
                ))
                .labelsHidden()
                .tint(Color.brickAccent)
                .disabled(schedule.modeID == nil)
            }
            
            HStack(spacing: 6) {
                ForEach(Array(chipDays.enumerated()), id: \.offset) { _, chip in
                    let on = schedule.weekdays.contains(chip.weekday)
                    Text(chip.label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(on ? Color.brickCard : Color.brickMuted)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(on ? Color.brickInk : Color.brickPanel)
                        )
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(schedule.daysString)
            
            Text(schedule.timeRangeString)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.brickInk)
            
            if let modeID = schedule.modeID,
               let mode = appState.modes.first(where: { $0.id == modeID }) {
                Text(mode.name)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.brickInk)
            } else {
                Text("Select mode to enable")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.brickMuted)
            }
            
            Text(schedule.nextRunString())
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.brickSecondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.brickCard)
        )
    }
}
