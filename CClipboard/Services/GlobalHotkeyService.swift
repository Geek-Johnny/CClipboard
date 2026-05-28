import Carbon
import Cocoa

class GlobalHotkeyService {
    private var hotKeyRef: EventHotKeyRef?
    var onHotkey: (() -> Void)?

    init() {
        register()
    }

    deinit {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
    }

    private func register() {
        // ⌘⇧V
        let keyCode = UInt32(kVK_ANSI_V)
        let modifiers: UInt32 = UInt32(cmdKey) | UInt32(shiftKey)
        var hotKeyID = EventHotKeyID(signature: 0x43434C50, id: 1)

        guard RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                                  GetApplicationEventTarget(), 0, &hotKeyRef) == noErr
        else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData -> OSStatus in
            guard let userData = userData else { return noErr }
            let service = Unmanaged<GlobalHotkeyService>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { service.onHotkey?() }
            return noErr
        }, 1, &eventType, selfPtr, nil)
    }
}
