import SwiftUI

struct HistoryRowView: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onCopy: () -> Void

    @EnvironmentObject var storage: ClipboardStorage
    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if item.type == .image, let nsImage = storage.loadImage(for: item) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipped()
                    .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(String(item.content.prefix(500)))
                    .lineLimit(item.type == .image ? 1 : 3)
                    .font(item.type == .image ? .caption : .body)
                    .foregroundColor(item.type == .image ? .secondary : .primary)

                Text(relativeTime(from: item.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isHovering || item.isPinned {
                Button {
                    withAnimation(.spring(duration: 0.2)) {
                        storage.togglePin(item)
                    }
                } label: {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .foregroundColor(item.isPinned ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "取消固定" : "固定")
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture {
            onCopy()
            NotificationCenter.default.post(name: .closeClipboardPanel, object: nil)
        }
    }

    private func relativeTime(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        switch interval {
        case ..<60:   return "刚刚"
        case ..<3600: return "\(Int(interval / 60))分钟前"
        case ..<86400: return "\(Int(interval / 3600))小时前"
        case ..<2592000: return "\(Int(interval / 86400))天前"
        default:      return "更早"
        }
    }
}
