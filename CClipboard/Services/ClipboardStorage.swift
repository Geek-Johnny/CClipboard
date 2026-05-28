import Combine
import Foundation

class ClipboardStorage: ObservableObject {
    @Published var items: [ClipboardItem] = []

    private let maxItems = 200
    private let saveURL: URL

    init() {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let directory = paths[0].appendingPathComponent("CClipboard")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        saveURL = directory.appendingPathComponent("clipboard_history.json")
        load()
    }

    func addItem(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        trimExcess()
        save()
    }

    func removeItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        save()
    }

    func clearAll() {
        items.removeAll()
        save()
    }

    private func trimExcess() {
        let pinned = items.filter { $0.isPinned }
        let unpinned = items.filter { !$0.isPinned }
        if unpinned.count > maxItems {
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
