//
//  ContentView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

struct ContentView: View {
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // 历史列表（包含搜索和底部按钮）
            HistoryListView(showSettings: $showSettings)
        }
        .frame(minWidth: 400, minHeight: 300)
        .background {
            if #available(macOS 14, *) {
                Color.clear
                    .background(.ultraThinMaterial)
            } else {
                Color(NSColor.windowBackgroundColor)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, DatabaseService.shared.context)
}
