//
//  ContentView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

struct ContentView: View {
    @State private var showSettings = false
    @State private var showProSheet = false
    @State private var proSheetContext: ProEntryContext = .normal
    @EnvironmentObject private var proManager: ProEntitlementManager

    var body: some View {
        VStack(spacing: 0) {
            // 历史列表（包含搜索和底部按钮）
            HistoryListView(showSettings: $showSettings, showProSheet: $showProSheet)
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
                .environmentObject(proManager)
        }
        .sheet(isPresented: $showProSheet) {
            ProSheetView(context: proSheetContext)
                .environmentObject(proManager)
        }
        .onChange(of: proManager.shouldShowProSheetBecauseTrialExpired) { shouldShow in
            if shouldShow {
                // 重置标记
                proManager.shouldShowProSheetBecauseTrialExpired = false
                // 弹出 Pro 面板（试用过期上下文）
                proSheetContext = .trialExpired
                showProSheet = true
            }
        }
        .onAppear {
            // 视图出现时检查状态
            proManager.recalcState()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, DatabaseService.shared.context)
}
