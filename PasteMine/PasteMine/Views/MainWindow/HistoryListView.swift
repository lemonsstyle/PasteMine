//
//  HistoryListView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

struct HistoryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.createdAt, ascending: false)],
        animation: .default
    )
    private var items: FetchedResults<ClipboardItem>
    
    @State private var searchText = ""
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return Array(items)
        } else {
            return items.filter { 
                ($0.content ?? "").localizedCaseInsensitiveContains(searchText)
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
                List {
                    ForEach(filteredItems) { item in
                        HistoryItemView(item: item)
                            .onTapGesture {
                                pasteItem(item)
                            }
                            .contextMenu {
                                Button("删除") {
                                    deleteItem(item)
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private func pasteItem(_ item: ClipboardItem) {
        guard let content = item.content else { return }
        PasteService.shared.paste(content: content)
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

