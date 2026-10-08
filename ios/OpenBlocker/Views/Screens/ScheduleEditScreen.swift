// Schedule editor - updated for minute-based times

import SwiftUI

struct ScheduleEditScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var appState = AppState.shared
    
    let schedule: BlockSchedule?
    
    @State private var name: String
    @State private var selectedModeID: UUID?
    @State private var startHour: Int
    @State private var startMinute: Int
    @State private var endHour: Int
    @State private var endMinute: Int
    @State private var selectedDays: Set<Int>
    @State private var isOn: Bool
    
    init(schedule: BlockSchedule? = nil) {
        self.schedule = schedule
        _name = State(initialValue: schedule?.name ?? "")
        _selectedModeID = State(initialValue: schedule?.modeID)
        
        let start = schedule?.startMinute ?? (9 * 60)
        let end = schedule?.endMinute ?? (17 * 60)
        
        _startHour = State(initialValue: start / 60)
        _startMinute = State(initialValue: start % 60)
        _endHour = State(initialValue: end / 60)
        _endMinute = State(initialValue: end % 60)
        _selectedDays = State(initialValue: schedule?.weekdays ?? [2, 3, 4, 5, 6])
        _isOn = State(initialValue: schedule?.isOn ?? false)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.brickCanvas
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Schedule Name")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.brickMuted)
                            
                            TextField("e.g. Work Hours", text: $name)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.brickCard)
                                )
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mode")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.brickMuted)
                            
                            Menu {
                                ForEach(appState.modes) { mode in
                                    Button(mode.name) {
                                        selectedModeID = mode.id
                                    }
                                }
                            } label: {
                                HStack {
                                    if let modeID = selectedModeID,
                                       let mode = appState.modes.first(where: { $0.id == modeID }) {
                                        Text(mode.name)
                                    } else {
                                        Text("Select mode")
                                            .foregroundColor(Color.brickMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(Color.brickInk)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.brickCard)
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.brickMuted)
                            
                            HStack {
                                VStack {
                                    Text("Start")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.brickMuted)
                                    HStack {
                                        Picker("Hour", selection: $startHour) {
                                            ForEach(0..<24) { Text("\($0)").tag($0) }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 60)
                                        Text(":")
                                        Picker("Minute", selection: $startMinute) {
                                            ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 60)
                                    }
                                }
                                
                                Text("to")
                                    .foregroundColor(Color.brickMuted)
                                
                                VStack {
                                    Text("End")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.brickMuted)
                                    HStack {
                                        Picker("Hour", selection: $endHour) {
                                            ForEach(0..<24) { Text("\($0)").tag($0) }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 60)
                                        Text(":")
                                        Picker("Minute", selection: $endMinute) {
                                            ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 60)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Days")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.brickMuted)
                            
                            HStack(spacing: 12) {
                                ForEach(1...7, id: \.self) { day in
                                    dayButton(day)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle(schedule == nil ? "New Schedule" : "Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSchedule()
                    }
                    .disabled(name.isEmpty || selectedModeID == nil)
                }
            }
        }
    }
    
    private func dayButton(_ weekday: Int) -> some View {
        let dayNames = ["S", "M", "T", "W", "T", "F", "S"]
        let isSelected = selectedDays.contains(weekday)
        
        return Button(action: {
            if isSelected {
                selectedDays.remove(weekday)
            } else {
                selectedDays.insert(weekday)
            }
        }) {
            Text(dayNames[weekday - 1])
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color.white : Color.brickInk)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Color.brickAccent : Color.brickCard)
                )
        }
    }
    
    private func saveSchedule() {
        let startMin = startHour * 60 + startMinute
        let endMin = endHour * 60 + endMinute
        
        if let existingSchedule = schedule {
            var updated = existingSchedule
            updated.name = name
            updated.modeID = selectedModeID
            updated.startMinute = startMin
            updated.endMinute = endMin
            updated.weekdays = selectedDays
            updated.isOn = isOn
            appState.updateSchedule(updated)
        } else {
            let newSchedule = BlockSchedule(
                name: name,
                weekdays: selectedDays,
                startMinute: startMin,
                endMinute: endMin,
                modeID: selectedModeID,
                isOn: isOn
            )
            appState.addSchedule(newSchedule)
        }
        dismiss()
    }
}
