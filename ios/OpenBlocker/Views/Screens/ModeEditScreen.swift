// Mode editor - simplified for new architecture

import SwiftUI
import FamilyControls

struct ModeEditScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var appState = AppState.shared
    
    let mode: BlockMode?
    
    @State private var name: String
    @State private var kind: BlockMode.Kind
    @State private var selection: FamilyActivitySelection
    @State private var showingAppPicker = false
    
    init(mode: BlockMode? = nil) {
        self.mode = mode
        _name = State(initialValue: mode?.name ?? "")
        _kind = State(initialValue: mode?.kind ?? .block)
        _selection = State(initialValue: mode?.selection ?? FamilyActivitySelection())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.brickCanvas
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mode Name")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.brickMuted)
                            
                            TextField("e.g. Work Focus", text: $name)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.brickCard)
                                )
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mode Type")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.brickMuted)
                            
                            Picker("Kind", selection: $kind) {
                                Text("Block").tag(BlockMode.Kind.block)
                                Text("Allow only").tag(BlockMode.Kind.allowOnly)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal)
                        
                        Button(action: { showingAppPicker = true }) {
                            VStack(spacing: 8) {
                                Text("Choose Apps & Categories")
                                    .font(.system(size: 17, weight: .medium))
                                
                                if !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty {
                                    Text("\(selection.applicationTokens.count) apps, \(selection.categoryTokens.count) categories selected")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.brickMuted)
                                }
                            }
                            .foregroundColor(Color.brickInk)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.brickCard)
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle(mode == nil ? "New Mode" : "Edit Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMode()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .familyActivityPicker(isPresented: $showingAppPicker, selection: $selection)
        }
    }
    
    private func saveMode() {
        if let existingMode = mode {
            var updated = existingMode
            updated.name = name
            updated.kind = kind
            updated.selection = selection
            appState.updateMode(updated)
        } else {
            let newMode = BlockMode(
                name: name,
                kind: kind,
                selection: selection
            )
            appState.addMode(newMode)
        }
        dismiss()
    }
}
