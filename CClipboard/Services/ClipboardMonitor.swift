import AppKit

class ClipboardMonitor {
    private weak var storage: ClipboardStorage?
    private var lastChangeCount: Int = -1
    private var timer: Timer?

    init(storage: ClipboardStorage) {
        self.storage = storage
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    private func startMonitoring() {
        captureCurrentContent()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func captureCurrentContent() {
        let pasteboard = NSPasteboard.general
        lastChangeCount = pasteboard.changeCount
        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            DispatchQueue.main.async {
                self.storage?.addItem(ClipboardItem(content: content))
            }
        }
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // 1) Text takes priority
        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            guard content != storage?.items.first?.content else { return }
            let item = ClipboardItem(type: .text, content: content)
            DispatchQueue.main.async { self.storage?.addItem(item) }
            return
        }

        // 2) Check for image
        guard let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil),
              let image = images.first as? NSImage,
              let pngData = image.pngData
        else { return }

        // dedup with last image item
        let hash = "\(pngData.count)-\(pngData.prefix(64).reduce(0) { $0 &* 127 &+ Int($1) })"
        if let lastItem = storage?.items.first, lastItem.imageHash == hash { return }

        DispatchQueue.main.async { [weak self] in
            self?.storage?.addImageItem(pngData: pngData, imageSize: image.size)
        }
    }
}

// MARK: - NSImage → PNG Data

private extension NSImage {
    var pngData: Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData)
        else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
