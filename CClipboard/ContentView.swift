import AppKit
import SwiftUI

extension Notification.Name {
    static let closeClipboardPanel = Notification.Name("closeClipboardPanel")
    static let performPaste = Notification.Name("performPaste")
}

struct ContentView: View {
    @EnvironmentObject var storage: ClipboardStorage
    @State private var searchText = ""
    @State private var selectedId: UUID?
    @FocusState private var isSearchFocused: Bool
    @FocusState private var isListFocused: Bool

    private var filteredItems: [ClipboardItem] {
        if searchText.isEmpty { return storage.items }
        return storage.items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            if filteredItems.isEmpty {
                emptyState
            } else {
                itemList
            }
            Divider()
            bottomBar
        }
        .frame(width: 360, height: 420)
        .onAppear {
            isSearchFocused = true
            if let first = filteredItems.first {
                selectedId = first.id
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .performPaste)) { _ in
            guard let id = selectedId,
                  let item = filteredItems.first(where: { $0.id == id })
            else { return }
            copyAndPaste(item)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索剪贴板历史...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .onKeyPress(.downArrow) {
                    guard !filteredItems.isEmpty else { return .ignored }
                    isSearchFocused = false
                    isListFocused = true
                    selectedId = filteredItems[0].id
                    return .handled
                }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    isSearchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
    }

    // MARK: - Item List

    private var itemList: some View {
        List(filteredItems, selection: $selectedId) { item in
            HistoryRowView(
                item: item,
                isSelected: selectedId == item.id,
                onCopy: { copyToClipboard(item) }
            )
            .environmentObject(storage)
            .tag(item.id)
        }
        .listStyle(.plain)
        .focused($isListFocused)
        .onKeyPress(.upArrow) {
            guard let id = selectedId,
                  let index = filteredItems.firstIndex(where: { $0.id == id }),
                  index == 0
            else { return .ignored }
            isListFocused = false
            isSearchFocused = true
            selectedId = nil
            return .handled
        }
    }

    // MARK: - Clipboard Actions

    private func copyToClipboard(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        if item.type == .image, let image = storage.loadImage(for: item) {
            NSPasteboard.general.writeObjects([image])
        } else {
            NSPasteboard.general.setString(item.content, forType: .string)
        }
    }

    private func copyAndPaste(_ item: ClipboardItem) {
        // Copy to clipboard first
        copyToClipboard(item)

        // Close panel → return to previous app
        NotificationCenter.default.post(name: .closeClipboardPanel, object: nil)

        // Cmd+V into the active app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            guard let source = CGEventSource(stateID: .combinedSessionState),
                  let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            else { return }
            keyDown.flags = .maskCommand
            keyUp.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "clipboard")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(searchText.isEmpty ? "暂无剪贴板历史" : "无匹配结果")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if !storage.items.isEmpty {
                Button {
                    storage.clearAll()
                } label: {
                    Label("清除全部", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            Spacer()
            Text("共 \(storage.items.count) 条")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
