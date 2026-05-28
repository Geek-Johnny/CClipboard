import AppKit
import Combine
import Foundation

class ClipboardStorage: ObservableObject {
    @Published var items: [ClipboardItem] = []

    private let maxItems = 200
    private let saveURL: URL
    let imageDir: URL

    init() {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let directory = paths[0].appendingPathComponent("CClipboard")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let imgDir = directory.appendingPathComponent("Images")
        try? FileManager.default.createDirectory(at: imgDir, withIntermediateDirectories: true)
        imageDir = imgDir

        saveURL = directory.appendingPathComponent("clipboard_history.json")
        load()
    }

    func addItem(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        trimExcess()
        save()
    }

    func addImageItem(pngData: Data, imageSize: NSSize) {
        let filename = "\(UUID().uuidString).png"
        let fileURL = imageDir.appendingPathComponent(filename)
        try? pngData.write(to: fileURL)

        let w = Int(imageSize.width)
        let h = Int(imageSize.height)
        let content = "图片 (\(w)×\(h), \(pngData.count / 1024) KB)"

        // simple hash for dedup
        let hash = "\(pngData.count)-\(pngData.prefix(64).reduce(0) { $0 &* 127 &+ Int($1) })"

        let item = ClipboardItem(
            type: .image,
            content: content,
            imagePath: filename,
            imageHash: hash
        )
        items.insert(item, at: 0)
        trimExcess()
        save()
    }

    func removeItem(_ item: ClipboardItem) {
        if let path = item.imagePath {
            try? FileManager.default.removeItem(at: imageDir.appendingPathComponent(path))
        }
        items.removeAll { $0.id == item.id }
        save()
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        save()
    }

    func clearAll() {
        for item in items {
            if let path = item.imagePath {
                try? FileManager.default.removeItem(at: imageDir.appendingPathComponent(path))
            }
        }
        items.removeAll()
        save()
    }

    func loadImage(for item: ClipboardItem) -> NSImage? {
        guard let path = item.imagePath else { return nil }
        let url = imageDir.appendingPathComponent(path)
        return NSImage(contentsOf: url)
    }

    private func trimExcess() {
        let pinned = items.filter { $0.isPinned }
        let unpinned = items.filter { !$0.isPinned }
        if unpinned.count > maxItems {
            let excess = unpinned.suffix(unpinned.count - maxItems)
            for item in excess {
                if let path = item.imagePath {
                    try? FileManager.default.removeItem(at: imageDir.appendingPathComponent(path))
                }
            }
            items = pinned + Array(unpinned.prefix(maxItems))
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data)
        else { return }
        items = decoded.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.timestamp > $1.timestamp
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: saveURL)
    }
}
