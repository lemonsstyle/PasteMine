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
            // 头部
            HeaderView(showSettings: $showSettings)

            // 历史列表
            HistoryListView()
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

struct HeaderView: View {
    @Binding var showSettings: Bool

    var body: some View {
        HStack {
            Text("剪贴板历史")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .help("设置")
        }
        .padding()
        .background {
            if #available(macOS 14, *) {
                Color.clear
                    .background(.regularMaterial, in: Rectangle())
            } else {
                Color(NSColor.windowBackgroundColor)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, DatabaseService.shared.context)
}
