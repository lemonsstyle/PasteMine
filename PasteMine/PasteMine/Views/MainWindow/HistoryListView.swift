//
//  HistoryListView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

// 通知名称：窗口显示时滚动到顶部
extension Notification.Name {
    static let scrollToTop = Notification.Name("scrollToTop")
}

struct HistoryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.createdAt, ascending: false)],
        animation: .default
    )
    private var items: FetchedResults<ClipboardItem>

    @State private var searchText = ""
    @State private var scrollToTopID: UUID = UUID()
    @State private var selectedIndex: Int = 0
    @State private var selectedFilter: AppSourceFilter? = nil
    @Binding var showSettings: Bool
    
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
                // 图片：搜索来源应用或"图片"关键字
                else if $0.itemType == .image {
                    let appMatch = ($0.appSource ?? "").localizedCaseInsensitiveContains(searchText)
                    let keywordMatch = "图片".localizedCaseInsensitiveContains(searchText) ||
                                       "image".localizedCaseInsensitiveContains(searchText)
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
                topApps: topApps,
                allApps: appStatistics
            )

            // 列表
            if filteredItems.isEmpty {
                EmptyStateView(message: searchText.isEmpty ? "暂无剪贴板历史" : "没有找到匹配的记录")
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
                                onPinToggle: { item in
                                    togglePin(item)
                                }
                            )
                                .id(item.id)
                                .onTapGesture {
                                    selectedIndex = index
                                    pasteItem(item)
                                }
                                .contextMenu {
                                    Button(item.isPinned ? "取消固定" : "固定") {
                                        togglePin(item)
                                    }
                                    Button("删除") {
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
                print("📌 \(item.isPinned ? "固定" : "取消固定")项目")
            } catch {
                print("❌ 保存失败: \(error)")
            }
        }
    }

    private func clearAll() {
        let alert = NSAlert()
        alert.messageText = "确定要清空所有历史记录吗？"
        alert.informativeText = "此操作不可撤销"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "清空")
        alert.addButton(withTitle: "取消")

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
                    Text("清空")
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
            .help("清空所有历史")
            .onHover { hovering in
                hoveringClear = hovering
            }

            Spacer()

            // 右侧：设置按钮
            Button(action: onSettings) {
                HStack(spacing: 4) {
                    Image(systemName: "gear")
                        .font(.system(size: 13))
                    Text("设置")
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
            .help("设置")
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
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class KeyEventHandlingView: NSView {
        var keyHandler: ((NSEvent) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            keyHandler?(event)
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

