import Foundation

struct BlockSession: Identifiable, Codable, Equatable {
    let id: UUID
    let startDate: Date
    var endDate: Date?
    let modeId: UUID
    let modeName: String
    var isScheduled: Bool
    
    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        modeId: UUID,
        modeName: String,
        isScheduled: Bool = false
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.modeId = modeId
        self.modeName = modeName
        self.isScheduled = isScheduled
    }
    
    var duration: TimeInterval {
        if let end = endDate {
            return end.timeIntervalSince(startDate)
        }
        return Date().timeIntervalSince(startDate)
    }
    
    var isActive: Bool {
        endDate == nil
    }
}
