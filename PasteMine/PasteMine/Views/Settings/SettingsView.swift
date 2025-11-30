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
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域
            Text("设置")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            // 可滚动内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // 用户体验组
                    HStack(spacing: 8) {
                        SettingsSectionView(title: "通知") {
                            VStack(alignment: .leading, spacing: 3) {
                                Toggle("", isOn: $settings.notificationEnabled)
                                    .toggleStyle(.switch)
                                    .onChange(of: settings.notificationEnabled) { _ in
                                        settings.save()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("复制时显示通知")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        SettingsSectionView(title: "音效") {
                            VStack(alignment: .leading, spacing: 3) {
                                Toggle("", isOn: $settings.soundEnabled)
                                    .toggleStyle(.switch)
                                    .onChange(of: settings.soundEnabled) { _ in
                                        settings.save()
                                        if settings.soundEnabled {
                                            SoundService.shared.playCopySound()
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("播放提示音效")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // 数据管理组
                    HStack(spacing: 8) {
                        SettingsSectionView(title: "历史记录上限") {
                            VStack(alignment: .leading, spacing: 3) {
                                Picker("", selection: $settings.maxHistoryCount) {
                                    ForEach(AppSettings.historyCountOptions, id: \.self) { count in
                                        Text("\(count) 条").tag(count)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: settings.maxHistoryCount) { _ in
                                    settings.save()
                                }

                                Text("超出自动删除")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        SettingsSectionView(title: "保留时间") {
                            VStack(alignment: .leading, spacing: 3) {
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
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // 图片设置
                    SettingsSectionView(title: "图片大小限制") {
                        VStack(alignment: .leading, spacing: 3) {
                            Picker("", selection: $settings.maxImageSize) {
                                ForEach(AppSettings.imageSizeOptions, id: \.self) { size in
                                    Text("\(size) MB").tag(size)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: settings.maxImageSize) { _ in
                                settings.save()
                            }

                            Text("超过此大小的图片不保存")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // 系统集成组
                    HStack(spacing: 8) {
                        SettingsSectionView(title: "全局快捷键") {
                            VStack(alignment: .leading, spacing: 3) {
                                ShortcutRecorderView(shortcut: $settings.globalShortcut)
                                    .onChange(of: settings.globalShortcut) { _ in
                                        settings.save()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("显示/隐藏窗口")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(minWidth: 240, maxWidth: .infinity)

                        SettingsSectionView(title: "开机自启动") {
                            VStack(alignment: .leading, spacing: 3) {
                                Toggle("", isOn: $settings.launchAtLogin)
                                    .toggleStyle(.switch)
                                    .onChange(of: settings.launchAtLogin) { newValue in
                                        settings.save()
                                        LaunchAtLoginService.shared.setLaunchAtLogin(enabled: newValue)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("自动启动应用")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(width: 140)
                    }
                }
                .padding(16)
            }

            Divider()

            // 底部按钮区域
            HStack {
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 420, height: 500)
        .background {
            if #available(macOS 14, *) {
                Color.clear
                    .background(.ultraThinMaterial)
            } else {
                Color(NSColor.windowBackgroundColor)
            }
        }
    }

    private var retentionDescription: String {
        if settings.retentionDays == 0 {
            return "历史记录将永久保存(直到手动删除或达到数量上限)"
        } else {
            return "超过 \(settings.retentionDays) 天的记录将被自动删除"
        }
    }
}

// 设置项玻璃卡片组件
struct SettingsSectionView<Content: View>: View {
    let title: String
    let content: Content
    @State private var isHovered = false

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            content
        }
        .padding(9)
        .background {
            if #available(macOS 14, *) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(isHovered ? 0.15 : 0.08),
                            radius: isHovered ? 8 : 4,
                            y: isHovered ? 4 : 2)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            }
        }
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    SettingsView()
}
