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
            
            // 通知设置
            VStack(alignment: .leading, spacing: 8) {
                Toggle("启用复制通知", isOn: $settings.notificationEnabled)
                    .onChange(of: settings.notificationEnabled) { _ in
                        settings.save()
                    }
                
                Text("复制文本时显示系统通知（显示前50个字符）")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 历史记录数量设置
            VStack(alignment: .leading, spacing: 8) {
                Text("历史记录上限")
                    .font(.headline)
                
                Picker("", selection: $settings.maxHistoryCount) {
                    ForEach(AppSettings.historyCountOptions, id: \.self) { count in
                        Text("\(count) 条").tag(count)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: settings.maxHistoryCount) { _ in
                    settings.save()
                }
                
                Text("超出上限时，自动删除最旧的记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 保留时间设置
            VStack(alignment: .leading, spacing: 8) {
                Text("保留时间")
                    .font(.headline)
                
                Picker("", selection: $settings.retentionDays) {
                    ForEach(AppSettings.retentionDaysOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: settings.retentionDays) { _ in
                    settings.save()
                }
                
                Text(retentionDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 图片大小限制设置
            VStack(alignment: .leading, spacing: 8) {
                Text("图片大小限制")
                    .font(.headline)
                
                Picker("", selection: $settings.maxImageSize) {
                    ForEach(AppSettings.imageSizeOptions, id: \.self) { size in
                        Text("\(size) MB").tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: settings.maxImageSize) { _ in
                    settings.save()
                }
                
                Text("超过此大小的图片将不会保存")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 全局快捷键设置
            VStack(alignment: .leading, spacing: 8) {
                Text("全局快捷键")
                    .font(.headline)
                
                ShortcutRecorderView(shortcut: $settings.globalShortcut)
                    .onChange(of: settings.globalShortcut) { _ in
                        settings.save()
                    }
                
                Text("用于显示/隐藏剪贴板历史窗口")
                    .font(.caption)
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
        .frame(width: 480, height: 600)
    }
    
    private var retentionDescription: String {
        if settings.retentionDays == 0 {
            return "历史记录将永久保存（直到手动删除或达到数量上限）"
        } else {
            return "超过 \(settings.retentionDays) 天的记录将被自动删除"
        }
    }
}

#Preview {
    SettingsView()
}

