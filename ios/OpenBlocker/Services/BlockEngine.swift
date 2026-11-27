// Adapted from Foqos (MIT, (c) 2024 Ali Waseem): Foqos/Utils/AppBlockerUtil.swift

import FamilyControls
import ManagedSettings

enum BlockEngine {
    static let store = ManagedSettingsStore(named: .init("openblocker.session"))
    
    /// Apply shields for a mode according to its kind and rules.
    static func apply(_ mode: BlockMode, rules: Rules) {
        #if targetEnvironment(simulator)
        return
        #else
        shield(mode, in: store, rules: rules)
        // Rules
        store.application.denyAppRemoval = rules.preventDelete
        store.application.denyAppInstallation = rules.blockInstalls
        store.appStore.denyInAppPurchases = rules.blockPurchases
        #endif
    }
    
    /// Extra blocks running at the same time as the main one each get their
    /// own store; iOS enforces the union of all stores' shields.
    static func applyExtras(_ extras: [(id: String, mode: BlockMode)], rules: Rules, previous: [String]) {
        #if targetEnvironment(simulator)
        return
        #else
        let keep = Set(extras.map(\.id))
        for id in previous where !keep.contains(id) {
            extraStore(id).clearAllSettings()
        }
        for extra in extras {
            shield(extra.mode, in: extraStore(extra.id), rules: rules)
        }
        #endif
    }
    
    private static func extraStore(_ id: String) -> ManagedSettingsStore {
        ManagedSettingsStore(named: .init("openblocker.extra.\(id)"))
    }
    
    private static func shield(_ mode: BlockMode, in store: ManagedSettingsStore, rules: Rules) {
        #if !targetEnvironment(simulator)
        let sel = mode.selection
        
        switch mode.kind {
        case .allowOnly:
            // Allow mode: block everything except what's selected
            store.shield.applications = nil
            store.shield.applicationCategories = .all(except: sel.applicationTokens)
            store.shield.webDomainCategories = .all(except: sel.webDomainTokens)
            
        case .block:
            // Block mode: block only what's selected
            store.shield.applications = sel.applicationTokens.isEmpty ? nil : sel.applicationTokens
            store.shield.applicationCategories = sel.categoryTokens.isEmpty ? nil : .specific(sel.categoryTokens)
            store.shield.webDomains = sel.webDomainTokens.isEmpty ? nil : sel.webDomainTokens
            store.shield.webDomainCategories = sel.categoryTokens.isEmpty ? nil : .specific(sel.categoryTokens)
        }
        
        // Typed domains
        let typed = Set(mode.typedDomains.map { WebDomain(domain: $0) })
        if rules.blockAdultWeb {
            store.webContent.blockedByFilter = .auto(typed)
        } else if !typed.isEmpty {
            store.webContent.blockedByFilter = .specific(typed)
        } else {
            store.webContent.blockedByFilter = nil
        }
        #endif
    }
    
    /// Clear all shields and restrictions.
    static func clear() {
        #if targetEnvironment(simulator)
        return
        #else
        store.clearAllSettings()
        #endif
    }
}
