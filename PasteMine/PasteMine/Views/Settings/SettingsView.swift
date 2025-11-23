//
//  SettingsView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

struct SettingsView: View {
    @State private var settings = AppSettings.load()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("设置")
                .font(.title)
            
            Divider()
            
            Toggle("启用复制通知", isOn: $settings.notificationEnabled)
                .onChange(of: settings.notificationEnabled) { _ in
                    settings.save()
                }
            
            Text("复制文本时显示系统通知（显示前50个字符）")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("全局快捷键")
                    .font(.headline)
                
                Text("⌘⇧V - 显示/隐藏剪贴板历史窗口")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#Preview {
    SettingsView()
}

