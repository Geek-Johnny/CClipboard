import Cocoa
import SwiftUI

class ClipboardWindowManager: NSObject {
    private var panel: NSPanel?
    private weak var storage: ClipboardStorage?
    private var eventMonitor: Any?
    private var notificationObserver: NSObjectProtocol?

    func setup(storage: ClipboardStorage) {
        self.storage = storage
    }

    deinit {
        removeEventMonitor()
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func togglePanel() {
        if panel?.isVisible == true {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let storage = storage else { return }

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 420),
                styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isMovableByWindowBackground = true
            panel.hasShadow = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.delegate = self
            self.panel = panel

            // 监听 ContentView 发起的关闭请求（回车粘贴后关闭）
            notificationObserver = NotificationCenter.default.addObserver(
                forName: .closeClipboardPanel,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.hidePanel()
            }
        }

        // 每次弹出重建视图，保证搜索/选中状态重置
        let contentView = ContentView()
            .environmentObject(storage)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 360, height: 420)
        panel?.contentView = hostingView

        // 居中显示
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let panelRect = panel!.frame
            let x = screenRect.midX - panelRect.width / 2
            let y = screenRect.midY - panelRect.height / 2
            panel?.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // 快捷键：Escape / ⌘W / Enter(回车粘贴)
        removeEventMonitor()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 // Escape
                || (event.keyCode == 13 && event.modifierFlags.contains(.command)) // ⌘W
            {
                self?.hidePanel()
                return nil
            }
            if event.keyCode == 36 { // Enter
                NotificationCenter.default.post(name: .performPaste, object: nil)
                return nil
            }
            return event
        }

        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hidePanel() {
        panel?.orderOut(nil)
        removeEventMonitor()
        NSApp.hide(nil) // 返回上一个应用的聚焦
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

// MARK: - NSWindowDelegate
extension ClipboardWindowManager: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        hidePanel()
    }
}
