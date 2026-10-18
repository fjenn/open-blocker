import Foundation
import FamilyControls

struct BlockMode: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var kind: Kind
    var selectionData: Data?
    var typedDomains: [String]
    var isDefault: Bool
    
    #if DEBUG
    var demoAppCount: Int?
    var demoWebsiteCount: Int?
    #endif
    
    enum Kind: String, Codable {
        case allowOnly
        case block
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        kind: Kind = .block,
        selection: FamilyActivitySelection? = nil,
        typedDomains: [String] = [],
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        if let selection = selection, let data = try? JSONEncoder().encode(selection) {
            self.selectionData = data
        } else {
            self.selectionData = nil
        }
        self.typedDomains = typedDomains
        self.isDefault = isDefault
    }
    
    var selection: FamilyActivitySelection {
        get {
            guard let data = selectionData,
                  let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
                return FamilyActivitySelection()
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                selectionData = data
            }
        }
    }
    
    var allowedAppCount: Int {
        #if DEBUG
        if let count = demoAppCount {
            return kind == .allowOnly ? count : 0
        }
        #endif
        
        let sel = selection
        return kind == .allowOnly ? sel.applicationTokens.count + sel.categoryTokens.count : 0
    }
    
    var blockedAppCount: Int {
        #if DEBUG
        if let count = demoAppCount {
            return kind == .block ? count : 0
        }
        #endif
        
        let sel = selection
        return kind == .block ? sel.applicationTokens.count + sel.categoryTokens.count : 0
    }
    
    var websiteCount: Int {
        #if DEBUG
        if let count = demoWebsiteCount {
            return count
        }
        #endif
        
        let sel = selection
        return sel.webDomainTokens.count + typedDomains.count
    }
    
    var subtitle: String {
        var parts: [String] = []
        
        switch kind {
        case .allowOnly:
            if allowedAppCount > 0 {
                parts.append("Allows \(allowedAppCount) app\(allowedAppCount == 1 ? "" : "s")")
            } else {
                parts.append("Blocks all apps")
            }
        case .block:
            if blockedAppCount > 0 {
                parts.append("Blocks \(blockedAppCount) app\(blockedAppCount == 1 ? "" : "s")")
            }
            if selection.categoryTokens.count > 0 {
                let count = selection.categoryTokens.count
                parts.append("\(count) categor\(count == 1 ? "y" : "ies")")
            }
        }
        
        if websiteCount > 0 {
            parts.append("\(websiteCount) website\(websiteCount == 1 ? "" : "s")")
        }
        
        return parts.isEmpty ? "Nothing chosen yet" : parts.joined(separator: " · ")
    }
    
    static func == (lhs: BlockMode, rhs: BlockMode) -> Bool {
        lhs.id == rhs.id
    }
}

/// The mode a fresh install starts with, so holding the key works right
/// after adding a key: the "Detox" template, which blocks every app.
/// Rename it any time.
enum ModeDefaults {
    static let starterTemplate = ModeTemplate.detox
    
    /// A copy of `config` with the starter mode, or nil when it already has modes.
    static func seeded(_ config: PolicyStore.Config) -> PolicyStore.Config? {
        guard config.modes.isEmpty else { return nil }
        var seeded = config
        let starter = starterTemplate.makeMode(isDefault: true)
        seeded.modes = [starter]
        seeded.activeModeID = starter.id
        return seeded
    }
}
