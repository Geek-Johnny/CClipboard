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
        guard let content = pasteboard.string(forType: .string), !content.isEmpty else { return }
        DispatchQueue.main.async {
            self.storage?.addItem(ClipboardItem(content: content))
        }
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let content = pasteboard.string(forType: .string), !content.isEmpty else { return }

        // 去重：与最近一条记录内容相同则跳过
        guard content != storage?.items.first?.content else { return }

        let item = ClipboardItem(content: content)
        DispatchQueue.main.async {
            self.storage?.addItem(item)
        }
    }
}
