import SwiftUI

@main
struct CClipboardApp: App {
    @StateObject private var storage: ClipboardStorage
    private let monitor: ClipboardMonitor
    private let windowManager: ClipboardWindowManager
    private let hotkey: GlobalHotkeyService

    init() {
        let storage = ClipboardStorage()
        self._storage = StateObject(wrappedValue: storage)
        self.monitor = ClipboardMonitor(storage: storage)

        let windowManager = ClipboardWindowManager()
        windowManager.setup(storage: storage)
        self.windowManager = windowManager

        let hotkey = GlobalHotkeyService()
        hotkey.onHotkey = { [windowManager] in
            windowManager.togglePanel()
        }
        self.hotkey = hotkey
    }

    var body: some Scene {
        MenuBarExtra("CClipboard", systemImage: "doc.on.clipboard") {
            ContentView()
                .environmentObject(storage)
        }
        .menuBarExtraStyle(.window)
    }
}
