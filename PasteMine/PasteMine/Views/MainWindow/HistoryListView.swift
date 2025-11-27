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
    @Binding var showSettings: Bool

    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return Array(items)
        } else {
            return items.filter {
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
    }

    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            SearchBarView(searchText: $searchText)

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
                            HistoryItemView(item: item, isSelected: index == selectedIndex)
                                .id(item.id)
                                .onTapGesture {
                                    selectedIndex = index
                                    pasteItem(item)
                                }
                                .contextMenu {
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
                    // 移除动画，立即删除
                    try? DatabaseService.shared.clearAll()
                    selectedIndex = 0
                }
            }
        } else {
            // 如果没有 keyWindow，直接显示对话框
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // 移除动画，立即删除
                try? DatabaseService.shared.clearAll()
                selectedIndex = 0
            }
        }
    }
}

// 底部操作栏
struct BottomActionBar: View {
    let onClearAll: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack {
            // 左侧：删除按钮
            Button(action: onClearAll) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("清空")
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("清空所有历史")

            Spacer()

            // 右侧：设置按钮
            Button(action: onSettings) {
                HStack(spacing: 4) {
                    Image(systemName: "gear")
                    Text("设置")
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("设置")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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

