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
            
            Spacer()
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
            .help("设置")
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, DatabaseService.shared.context)
}
