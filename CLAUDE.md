# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build (debug)
xcodebuild -project CClipboard.xcodeproj -scheme CClipboard build

# Build (release)
xcodebuild -project CClipboard.xcodeproj -scheme CClipboard build -configuration Release

# Run tests
xcodebuild -project CClipboard.xcodeproj -scheme CClipboard test

# Open in Xcode
open CClipboard.xcodeproj
```

## Architecture

- **macOS app** built with SwiftUI (Swift 5.0, Xcode 26.5+, targeting macOS).
- Uses `PBXFileSystemSynchronizedRootGroup` in the Xcode project — any `.swift` file added to the `CClipboard/` directory is automatically picked up by the build system with no project file changes needed.
- No external package dependencies.
- App Sandbox is enabled; `ENABLE_USER_SELECTED_FILES` set to `readonly`.

## 项目结构

```
CClipboard/
  CClipboardApp.swift            # @main app入口，MenuBarExtra场景
  ContentView.swift              # 主弹窗视图（搜索栏 + 历史列表）
  Models/
    ClipboardItem.swift          # 剪贴板数据模型
  Services/
    ClipboardMonitor.swift       # 剪贴板轮询检测服务
    ClipboardStorage.swift       # JSON文件持久化存储
    ClipboardWindowManager.swift # 浮动面板管理（快捷键弹出）
    GlobalHotkeyService.swift    # 全局快捷键（⇧⌘V）
  Views/
    HistoryRowView.swift         # 单条历史记录行视图
```

## 版本 v1.0 — 功能清单

- [x] 菜单栏常驻图标（`doc.on.clipboard` SF Symbol）
- [x] 剪贴板文本自动监听（0.5s 轮询）
- [x] JSON 持久化存储（上限 200 条）
- [x] 搜索历史记录（实时过滤）
- [x] 条目固定/取消固定（pin）
- [x] 相对时间显示（刚刚/N分钟前/N小时前/天前/更早）
- [x] 点击复制到剪贴板 + 自动关闭窗口 + 回到上一个应用
- [x] 键盘导航（↑↓选择，回车粘贴到原应用）
- [x] 全局快捷键 ⇧⌘V 弹出浮动面板
- [x] 清除全部历史
- [x] Escape / ⌘W 关闭窗口

## 交互方式

| 操作 | 行为 |
|------|------|
| **点击条目** | 复制 → 关闭窗口 → 回到上一个应用 |
| **回车** | 复制 → 关闭窗口 → 聚焦原应用 → 自动 Cmd+V 粘贴 |
| **↑↓** | 列表导航 |
| **⇧⌘V** | 全局快捷键打开面板 |
| **Escape / ⌘W** | 关闭面板 |

## 开发计划

### 第一阶段 ✅ 项目结构搭建
- 创建文件目录结构
- 定义数据模型 `ClipboardItem`

### 第二阶段 ✅ 剪贴板监听
- 通过 `NSTimer` 定期轮询 `NSPasteboard.changeCount`
- 检测到变化时读取剪贴板文本内容
- 去重（连续相同内容不重复记录）

### 第三阶段 ✅ 数据持久化
- 使用 JSON 文件存储在 `Application Support` 目录
- 支持增删查、固定/取消固定
- 限制最大历史条数（默认 200 条）

### 第四阶段 ✅ 菜单栏 UI
- `MenuBarExtra` 实现菜单栏常驻图标
- `.menuBarExtraStyle(.window)` 弹窗风格
- 搜索框 + 历史列表 + 清除按钮

### 第五阶段 ✅ 交互与细节
- 点击条目自动复制到剪贴板 + 窗口关闭 + 回到上一个应用
- 键盘导航（上下箭头选择，回车自动粘贴）
- 条目固定（pin）功能
- 全局快捷键 ⇧⌘V
- Escape / ⌘W 关闭
- 相对时间显示 + 空状态提示

### 第六阶段 ⬜ 图片支持
- 扩展模型支持图片类型（type + imageData）
- 监听 NSPasteboard 图片内容
- 图片缩略图显示
- 图片文件存储（文件系统而非 JSON）
- 点击图片项恢复到剪贴板

## 技术要点

- **剪贴板轮询**：`Timer` 每 0.5s 检查 `NSPasteboard.changeCount`，只在变化时读取内容
- **存储路径**：`FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first`
- **限制**：固定项不受数量限制，普通项超 200 条自动丢弃最旧
- **去重**：跳过完全相同的连续复制
- **全局快捷键**：Carbon `RegisterEventHotKey`
- **浮动面板**：`NSPanel` + `.nonactivatingPanel`，`NSApp.hide(nil)` 返回上一个应用
- **隐私**：App Sandbox 下 NSPasteboard 读取正常，无需特殊权限

## Conventions

- SwiftUI views use `#Preview` macros for previews.
- The project uses `GENERATE_INFOPLIST_FILE` — no manual Info.plist.
- Build settings use `SWIFT_APPROACHABLE_CONCURRENCY` and `SWIFT_DEFAULT_ACTOR_ISOLATION` (`MainActor`).
