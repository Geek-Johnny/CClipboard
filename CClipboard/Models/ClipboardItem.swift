import Foundation

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
    var isPinned: Bool

    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isPinned = isPinned
    }
}
