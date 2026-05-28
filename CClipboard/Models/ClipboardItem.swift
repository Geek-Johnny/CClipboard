import Foundation

enum ItemType: String, Codable {
    case text
    case image
}

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let type: ItemType
    let content: String
    let timestamp: Date
    var isPinned: Bool
    var imagePath: String?
    var imageHash: String?

    init(
        id: UUID = UUID(),
        type: ItemType = .text,
        content: String,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        imagePath: String? = nil,
        imageHash: String? = nil
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.imagePath = imagePath
        self.imageHash = imageHash
    }

    enum CodingKeys: String, CodingKey {
        case id, type, content, timestamp, isPinned, imagePath, imageHash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decodeIfPresent(ItemType.self, forKey: .type) ?? .text
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        imageHash = try container.decodeIfPresent(String.self, forKey: .imageHash)
    }
}
