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
            SearchBarView(searchText: $searchText, onClearAll: clearAll)
            
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

                        ForEach(filteredItems) { item in
                            HistoryItemView(item: item)
                                .id(item.id)
                                .onTapGesture {
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
                    .background {
                        if #available(macOS 14, *) {
                            Color.clear
                        } else {
                            Color(NSColor.windowBackgroundColor)
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .scrollToTop)) { _ in
                        // 窗口显示时，滚动到顶部
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                    .onAppear {
                        // 首次显示时也滚动到顶部
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func pasteItem(_ item: ClipboardItem) {
        PasteService.shared.paste(item: item)
    }
    
    private func deleteItem(_ item: ClipboardItem) {
        withAnimation {
            try? DatabaseService.shared.delete(item)
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
                    withAnimation {
                        try? DatabaseService.shared.clearAll()
                    }
                }
            }
        } else {
            // 如果没有 keyWindow，直接显示对话框
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                withAnimation {
                    try? DatabaseService.shared.clearAll()
                }
            }
        }
    }
}

