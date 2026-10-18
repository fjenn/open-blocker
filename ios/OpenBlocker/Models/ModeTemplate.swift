import Foundation

/// Starting points offered when you create a mode. A template sets the name,
/// the behavior and, where it fits, a suggested schedule. Screen Time never
/// lets an app pre-select apps for you, so templates that need apps open the
/// picker and you choose them.
enum ModeTemplate: String, CaseIterable, Identifiable {
    case deepWork
    case sleep
    case mindfulness
    case familyTime
    case detox
    case blank
    
    var id: String { rawValue }
    
    /// Suggested name. Blank starts empty so you name it yourself.
    var name: String {
        switch self {
        case .deepWork: return "Deep work"
        case .sleep: return "Sleep"
        case .mindfulness: return "Mindfulness"
        case .familyTime: return "Family time"
        case .detox: return "Detox"
        case .blank: return ""
        }
    }
    
    /// Title shown on the template card.
    var title: String { self == .blank ? "Blank" : name }
    
    var summary: String {
        switch self {
        case .deepWork: return "Block the apps that pull you away while you focus. You pick them next."
        case .sleep: return "Only the apps you pick stay on at night, like Phone and Clock."
        case .mindfulness: return "Block feeds, news and games so you can be where you are."
        case .familyTime: return "Only the apps you pick stay on, like Phone and Camera."
        case .detox: return "Block every app. Nothing to pick."
        case .blank: return "Start empty and set it up your way."
        }
    }
    
    var symbol: String {
        switch self {
        case .deepWork: return "scope"
        case .sleep: return "moon"
        case .mindfulness: return "leaf"
        case .familyTime: return "figure.2.and.child.holdinghands"
        case .detox: return "circle.slash"
        case .blank: return "square.dashed"
        }
    }
    
    var kind: BlockMode.Kind {
        switch self {
        case .deepWork, .mindfulness, .blank: return .block
        case .sleep, .familyTime, .detox: return .allowOnly
        }
    }
    
    /// True when the mode only makes sense once you pick apps, so the
    /// Screen Time picker opens right after choosing the template.
    var opensAppPicker: Bool {
        switch self {
        case .deepWork, .sleep, .mindfulness, .familyTime: return true
        case .detox, .blank: return false
        }
    }
    
    /// When this mode usually runs, offered as an optional schedule.
    /// Weekdays use Calendar numbering (1 is Sunday).
    private var suggestedWindow: (weekdays: Set<Int>, start: Int, end: Int)? {
        let everyDay: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
        switch self {
        case .deepWork: return ([2, 3, 4, 5, 6], 9 * 60, 12 * 60)
        case .sleep: return (everyDay, 22 * 60, 7 * 60)
        case .mindfulness: return (everyDay, 7 * 60, 8 * 60)
        case .familyTime: return (everyDay, 18 * 60, 20 * 60)
        case .detox, .blank: return nil
        }
    }
    
    /// A new, unsaved mode built from this template.
    func makeMode(isDefault: Bool = false) -> BlockMode {
        BlockMode(name: name, kind: kind, isDefault: isDefault)
    }
    
    /// The suggested schedule for `mode`, switched on, or nil when the
    /// template has no usual time.
    func suggestedSchedule(for mode: BlockMode) -> BlockSchedule? {
        guard let window = suggestedWindow else { return nil }
        return BlockSchedule(
            name: mode.name,
            weekdays: window.weekdays,
            startMinute: window.start,
            endMinute: window.end,
            modeID: mode.id,
            isOn: true
        )
    }
    
    /// "Every day, 10:00 PM - 7:00 AM", or nil without a suggestion.
    var scheduleSummary: String? {
        suggestedSchedule(for: makeMode()).map { "\($0.daysString), \($0.timeRangeString)" }
    }
}

/// Mode names are always the user's own words.
enum ModeName {
    static let placeholder = "e.g. Deep work"
    
    /// The trimmed name, or nil when it is empty (an unnamed mode can't be saved).
    static func validated(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
