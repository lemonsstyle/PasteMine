//
//  HistoryListView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI
import AppKit
import Combine

// 通知名称：窗口显示时滚动到顶部
extension Notification.Name {
    static let scrollToTop = Notification.Name("scrollToTop")
}

struct HistoryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var proManager: ProEntitlementManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.createdAt, ascending: false)],
        animation: .default
    )
    private var items: FetchedResults<ClipboardItem>

    @State private var searchText = ""
    @State private var scrollToTopID: UUID = UUID()
    @State private var selectedIndex: Int = 0
    @State private var selectedFilter: AppSourceFilter? = nil
    @State private var hasAccessibilityPermission = NSApplication.shared.hasAccessibilityPermission
    @State private var imagePreviewEnabled = AppSettings.load().imagePreviewEnabled
    @State private var previewWorkItem: DispatchWorkItem?
    @State private var isPinLimitTooltipVisible = false  // 显示固定限制气泡提示
    @State private var isSourceFilterTooltipVisible = false  // 显示来源筛选限制气泡提示
    @State private var lockedItemID: UUID?  // 触发锁图标动画的项ID
    @Binding var showSettings: Bool
    @Binding var showProSheet: Bool
    
    // 统计所有应用出现次数（使用 bundleId 作为唯一标识）
    var appStatistics: [AppSourceFilter] {
        var appData: [String: (displayName: String, bundleId: String?, count: Int)] = [:]
        
        for item in items {
            if let appSource = item.appSource, !appSource.isEmpty {
                // 使用 bundleId 作为 key（如果有的话），否则用 displayName
                let key = item.appBundleId ?? appSource
                
                if let existing = appData[key] {
                    appData[key] = (existing.displayName, existing.bundleId, existing.count + 1)
                } else {
                    appData[key] = (appSource, item.appBundleId, 1)
                }
            }
        }
        
        // 按次数排序
        return appData.map { AppSourceFilter(appName: $0.value.displayName, bundleId: $0.value.bundleId, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    
    // 前2个最常用的应用
    var topApps: [AppSourceFilter] {
        Array(appStatistics.prefix(2))
    }

    var filteredItems: [ClipboardItem] {
        var items: [ClipboardItem] = Array(self.items)
        
        // 应用来源筛选（优先用 bundleId 匹配，没有则用 displayName）
        if let filter = selectedFilter, !filter.appName.isEmpty {
            items = items.filter { item in
                if let bundleId = filter.bundleId, !bundleId.isEmpty {
                    // 如果 filter 有 bundleId，优先用 bundleId 匹配
                    return item.appBundleId == bundleId
                } else {
                    // 否则用 displayName 匹配（兼容旧数据）
                    return item.appSource == filter.appName
                }
            }
        }
        
        // 搜索文本筛选
        if !searchText.isEmpty {
            items = items.filter {
                // 文本：搜索内容
                if $0.itemType == .text {
                    return ($0.content ?? "").localizedCaseInsensitiveContains(searchText)
                }
                // 图片：搜索来源应用或 "image" 关键字
                else if $0.itemType == .image {
                    let appMatch = ($0.appSource ?? "").localizedCaseInsensitiveContains(searchText)
                    let keywordMatch = "image".localizedCaseInsensitiveContains(searchText)
                    return appMatch || keywordMatch
                }
                return false
            }
        }

        // 排序：固定的项目在前，按固定时间降序；未固定的按创建时间降序
        return items.sorted { item1, item2 in
            if item1.isPinned && !item2.isPinned {
                return true  // item1 固定，item2 未固定 -> item1 在前
            } else if !item1.isPinned && item2.isPinned {
                return false  // item1 未固定，item2 固定 -> item2 在前
            } else if item1.isPinned && item2.isPinned {
                // 两个都固定，按固定时间降序（后固定的在前）
                return (item1.pinnedAt ?? Date.distantPast) > (item2.pinnedAt ?? Date.distantPast)
            } else {
                // 两个都未固定，按创建时间降序
                return (item1.createdAt ?? Date.distantPast) > (item2.createdAt ?? Date.distantPast)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏和筛选器
            SearchBarView(
                searchText: $searchText,
                selectedFilter: $selectedFilter,
                showProSheet: $showProSheet,
                isSourceFilterTooltipVisible: $isSourceFilterTooltipVisible,
                topApps: topApps,
                allApps: appStatistics
            )
            
            if !hasAccessibilityPermission {
                PermissionBannerView(
                    title: L10n.text("未授予辅助功能权限", "Accessibility permission not granted"),
                    message: L10n.text("自动粘贴将降级为仅复制。前往【系统设置 > 隐私与安全 > 辅助功能 > 点击+ 选择 PasteMine】开启权限即可恢复。", "Auto-paste will fall back to copy only. Go to System Settings > Privacy & Security > Accessibility > Click + and select PasteMine to enable."),
                    actionTitle: L10n.text("前往设置", "Open Settings"),
                    action: openAccessibilitySettings
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }

            // 列表
            if filteredItems.isEmpty {
                EmptyStateView(message: searchText.isEmpty ? AppText.MainWindow.emptyStateTitle : AppText.Common.noMatches)
            } else {
                ScrollViewReader { proxy in
                    List {
                        // 顶部锚点（用于滚动定位）
                        Color.clear
                            .frame(height: 0)
                            .id("top")

                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            HistoryItemView(
                                item: item,
                                isSelected: index == selectedIndex,
                                showLockAnimation: lockedItemID == item.id,
                                onPinToggle: { item in
                                    togglePin(item)
                                },
                                onHoverChanged: { hovering in
                                    handleHoverPreview(for: item, hovering: hovering)
                                }
                            )
                                .id(item.id)
                                .onTapGesture {
                                    selectedIndex = index
                                    pasteItem(item)
                                }
                                .contextMenu {
                                    Button(item.isPinned ? AppText.Common.unpinned : AppText.Common.pinned) {
                                        togglePin(item)
                                    }
                                    Button(AppText.Common.delete) {
                                        deleteItem(item)
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.automatic, axes: .vertical)
                    .background(ScrollViewConfigurator())
                    .background {
                        if #available(macOS 14, *) {
                            Color.clear
                        } else {
                            Color(NSColor.windowBackgroundColor)
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .scrollToTop)) { _ in
                        // 窗口显示时，滚动到顶部，重置选中项
                        selectedIndex = 0
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                    .onAppear {
                        // 首次显示时也滚动到顶部
                        selectedIndex = 0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                    }
                    .onKeyboardEvent { event in
                        handleKeyPress(event: event, proxy: proxy)
                    }
                }
            }

            // 底部操作栏
            BottomActionBar(onClearAll: clearAll, onSettings: { showSettings = true })
        }
        .overlay(alignment: .top) {
            // 固定限制气泡提示
            if isPinLimitTooltipVisible {
                PinLimitTooltipView()
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
            }

            // 来源筛选限制气泡提示
            if isSourceFilterTooltipVisible {
                SourceFilterTooltipView()
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.3), value: isPinLimitTooltipVisible)
        .animation(.spring(response: 0.3), value: isSourceFilterTooltipVisible)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification, object: nil)) { _ in
            hasAccessibilityPermission = NSApplication.shared.hasAccessibilityPermission
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            imagePreviewEnabled = AppSettings.load().imagePreviewEnabled
            if !imagePreviewEnabled {
                ImagePreviewWindow.shared.hide()
            }
        }
    }

    private func handleKeyPress(event: NSEvent, proxy: ScrollViewProxy) {
        guard !filteredItems.isEmpty else { return }

        switch Int(event.keyCode) {
        case 125: // 下箭头
            if selectedIndex < filteredItems.count - 1 {
                selectedIndex += 1
                scrollToSelected(proxy: proxy)
            }
        case 126: // 上箭头
            if selectedIndex > 0 {
                selectedIndex -= 1
                scrollToSelected(proxy: proxy)
            }
        case 36: // 回车
            if selectedIndex < filteredItems.count {
                pasteItem(filteredItems[selectedIndex])
            }
        default:
            break
        }
    }

    private func scrollToSelected(proxy: ScrollViewProxy) {
        if selectedIndex < filteredItems.count {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(filteredItems[selectedIndex].id, anchor: .center)
            }
        }
    }

    private func pasteItem(_ item: ClipboardItem) {
        PasteService.shared.paste(item: item)
    }

    private func deleteItem(_ item: ClipboardItem) {
        // 使用快速动画删除单条记录
        withAnimation(.easeOut(duration: 0.15)) {
            try? DatabaseService.shared.delete(item)
        }
        // 调整选中索引
        if selectedIndex >= filteredItems.count - 1 && selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    private func togglePin(_ item: ClipboardItem) {
        // 🎉 所有用户都可以无限固定，无需检查限制

        withAnimation(.easeOut(duration: 0.2)) {
            item.isPinned.toggle()
            if item.isPinned {
                item.pinnedAt = Date()  // 设置固定时间
            } else {
                item.pinnedAt = nil  // 清除固定时间
            }

            // 保存到 Core Data
            do {
                try viewContext.save()
                print("📌 \(item.isPinned ? "Pinned" : "Unpinned") item")
            } catch {
                print("❌ 保存失败: \(error)")
            }
        }
    }
    
    private func showProUpgradeAlert() {
        let alert = NSAlert()
        alert.messageText = AppText.Pro.unlimitedPinsTitle
        alert.informativeText = AppText.Pro.unlimitedPinsMessage
        alert.alertStyle = .informational
        alert.addButton(withTitle: AppText.Pro.upgradeToPro)
        alert.addButton(withTitle: AppText.Common.cancel)

        // 添加"不再显示"勾选框
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = L10n.text("不再显示", "Don't show this again")

        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window) { [self] response in
                // 保存"不再显示"选项
                if alert.suppressionButton?.state == .on {
                    var settings = AppSettings.load()
                    settings.hidePinLimitAlert = true
                    settings.save()
                }

                if response == .alertFirstButtonReturn {
                    // 打开 Pro 面板
                    showProSheet = true
                }
            }
        } else {
            let response = alert.runModal()

            // 保存"不再显示"选项
            if alert.suppressionButton?.state == .on {
                var settings = AppSettings.load()
                settings.hidePinLimitAlert = true
                settings.save()
            }

            if response == .alertFirstButtonReturn {
                // 打开 Pro 面板
                showProSheet = true
            }
        }
    }

    private func clearAll() {
        let alert = NSAlert()
        alert.messageText = AppText.Pro.clearAllTitle
        alert.informativeText = AppText.Pro.clearAllMessage
        alert.alertStyle = .warning
        alert.addButton(withTitle: AppText.MainWindow.clearAll)
        alert.addButton(withTitle: AppText.Common.cancel)

        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    // 立即关闭窗口，让用户看不到删除过程
                    AppDelegate.shared?.windowManager?.hide()

                    // 在后台执行删除操作
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            try DatabaseService.shared.clearAll()
                            print("🗑️  后台删除完成")

                            // 在主线程更新 UI 状态
                            DispatchQueue.main.async {
                                self.selectedIndex = 0
                            }
                        } catch {
                            print("❌ 删除失败: \(error)")
                        }
                    }
                }
            }
        } else {
            // 如果没有 keyWindow，直接显示对话框
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // 立即关闭窗口
                AppDelegate.shared?.windowManager?.hide()

                // 在后台执行删除
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try DatabaseService.shared.clearAll()
                        print("🗑️  后台删除完成")

                        DispatchQueue.main.async {
                            self.selectedIndex = 0
                        }
                    } catch {
                        print("❌ 删除失败: \(error)")
                    }
                }
            }
        }
    }
    
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func handleHoverPreview(for item: ClipboardItem, hovering: Bool) {
        previewWorkItem?.cancel()

        // 🎉 所有用户都可以使用图片预览功能（需开启设置）
        guard imagePreviewEnabled,
              item.itemType == .image,
              let image = item.image else {
            ImagePreviewWindow.shared.hide()
            return
        }

        if hovering {
            let work = DispatchWorkItem {
                let anchorWindow = NSApp.mainWindow
                ImagePreviewWindow.shared.show(image: image, anchor: anchorWindow)
            }
            previewWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: work)
        } else {
            ImagePreviewWindow.shared.hide()
        }
    }

    // 显示固定限制气泡提示
    private func showPinLimitTooltip() {
        isPinLimitTooltipVisible = true
        // 2秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isPinLimitTooltipVisible = false
        }
    }

    // 触发锁图标动画
    private func triggerLockIconAnimation(for item: ClipboardItem) {
        lockedItemID = item.id
        // 动画结束后清除状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            lockedItemID = nil
        }
    }
}

// 图片预览窗口控制
final class ImagePreviewWindow {
    static let shared = ImagePreviewWindow()
    
    private var panel: NSPanel?
    private let size = NSSize(width: 320, height: 320)
    private let cornerRadius: CGFloat = 12
    private var isVisible: Bool = false
    
    private init() {}
    
    private func ensurePanel() -> NSPanel {
        if let panel = panel { return panel }
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.hudWindow, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovable = false
        self.panel = panel
        return panel
    }
    
    func show(image: NSImage, anchor: NSWindow?) {
        let panel = ensurePanel()
        panel.contentView = NSHostingView(rootView: ImagePreviewContent(image: image))
        
        if let anchor = anchor, let screen = anchor.screen {
            let anchorFrame = anchor.frame
            var origin = NSPoint(
                x: anchorFrame.maxX + 12,
                y: anchorFrame.midY - size.height / 2
            )
            
            let visible = screen.visibleFrame
            // Clamp horizontally
            if origin.x + size.width > visible.maxX {
                origin.x = anchorFrame.minX - size.width - 12
            }
            if origin.x < visible.minX {
                origin.x = visible.minX + 8
            }
            // Clamp vertically
            if origin.y + size.height > visible.maxY {
                origin.y = visible.maxY - size.height - 8
            }
            if origin.y < visible.minY {
                origin.y = visible.minY + 8
            }
            
            panel.setFrame(NSRect(origin: origin, size: size), display: true, animate: false)
        }
        
        if !isVisible {
            panel.alphaValue = 0
            panel.orderFront(nil)
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.15
                panel.animator().alphaValue = 1
            }
            isVisible = true
        } else {
            panel.orderFront(nil)
        }
    }
    
    func hide() {
        guard let panel = panel, isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            panel.alphaValue = 1
            self?.isVisible = false
        })
    }
}

struct ImagePreviewContent: View {
    let image: NSImage
    private let cornerRadius: CGFloat = 12
    
    var body: some View {
        VStack(spacing: 0) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if #available(macOS 14, *) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(NSColor.windowBackgroundColor))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}

// 底部操作栏
struct BottomActionBar: View {
    let onClearAll: () -> Void
    let onSettings: () -> Void
    
    @State private var hoveringClear = false
    @State private var hoveringSettings = false

    var body: some View {
        HStack {
            // 左侧：清空按钮
            Button(action: onClearAll) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                    Text(AppText.MainWindow.clearAll)
                        .font(.system(size: 13))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(hoveringClear ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.08))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(L10n.text("清空所有历史", "Clear all history"))
            .onHover { hovering in
                hoveringClear = hovering
            }

            Spacer()

            // 右侧：设置按钮
            Button(action: onSettings) {
                HStack(spacing: 4) {
                    Image(systemName: "gear")
                        .font(.system(size: 13))
                    Text(AppText.MainWindow.settings)
                        .font(.system(size: 13))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(hoveringSettings ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.08))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(AppText.MainWindow.settings)
            .onHover { hovering in
                hoveringSettings = hovering
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background {
            if #available(macOS 14, *) {
                Color.clear
                    .background(.regularMaterial, in: Rectangle())
            } else {
                Color(NSColor.controlBackgroundColor)
            }
        }
    }
}

struct PermissionBannerView: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(actionTitle) {
                action()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// 键盘事件监听扩展
extension View {
    func onKeyboardEvent(_ handler: @escaping (NSEvent) -> Void) -> some View {
        self.background(KeyboardEventView(handler: handler))
    }
}

struct KeyboardEventView: NSViewRepresentable {
    let handler: (NSEvent) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyEventHandlingView()
        view.keyHandler = handler
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // 每次更新时，尝试获取焦点
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    class KeyEventHandlingView: NSView {
        var keyHandler: ((NSEvent) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            keyHandler?(event)
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            // 窗口加载时立即获取焦点
            DispatchQueue.main.async {
                self.window?.makeFirstResponder(self)
            }
        }

        override func becomeFirstResponder() -> Bool {
            true
        }
    }
}

// 滚动条外观配置器
struct ScrollViewConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let scrollView = view.enclosingScrollView {
                scrollView.scrollerStyle = .overlay
                scrollView.hasVerticalScroller = true
                scrollView.autohidesScrollers = false

                // 设置滚动条样式为深色
                if #available(macOS 14, *) {
                    scrollView.scrollerKnobStyle = .dark
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let scrollView = nsView.enclosingScrollView {
            scrollView.scrollerStyle = .overlay
            if #available(macOS 14, *) {
                scrollView.scrollerKnobStyle = .dark
            }
        }
    }
}

// 固定限制气泡提示视图
struct PinLimitTooltipView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .foregroundColor(.blue)
                .font(.system(size: 14))

            Text(L10n.text("免费版最多固定 2 条，升级 Pro 可解锁无限固定", "Free plan: 2 pins max. Upgrade to Pro for unlimited pins"))
                .font(.system(size: 13))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        )
        .padding(.horizontal)
    }
}
