//
//  SettingsView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

// 设置分组枚举
enum SettingsGroup: String, CaseIterable {
    case general = "通用"
    case storage = "存储"
    case privacy = "隐私"

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .storage: return "internaldrive"
        case .privacy: return "lock.shield"
        }
    }
}

struct SettingsView: View {
    @State private var settings = AppSettings.load()
    @State private var selectedGroup: SettingsGroup = .general
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

            // 分组选择器
            HStack(spacing: 8) {
                ForEach(SettingsGroup.allCases, id: \.self) { group in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedGroup = group
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: group.icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedGroup == group ? .accentColor : .secondary)
                            Text(group.rawValue)
                                .font(.caption)
                                .foregroundColor(selectedGroup == group ? .accentColor : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedGroup == group ? Color.accentColor.opacity(0.1) : Color.clear)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 16)

            // 可滚动内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    switch selectedGroup {
                    case .general:
                        generalSettings
                    case .storage:
                        storageSettings
                    case .privacy:
                        privacySettings
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

    // 通用设置
    @ViewBuilder
    private var generalSettings: some View {
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

    // 存储设置
    @ViewBuilder
    private var storageSettings: some View {
        SettingsSectionView(title: "历史记录上限") {
            VStack(alignment: .leading, spacing: 3) {
                Picker("", selection: $settings.maxHistoryCount) {
                    ForEach(AppSettings.historyCountOptions, id: \.self) { count in
                        Text(count == 999 ? "永久" : "\(count) 条").tag(count)
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
        .frame(maxWidth: 320)

        SettingsSectionView(title: "忽略大图片以节省磁盘空间") {
            VStack(alignment: .leading, spacing: 3) {
                Toggle("", isOn: $settings.ignoreLargeImages)
                    .toggleStyle(.switch)
                    .onChange(of: settings.ignoreLargeImages) { _ in
                        settings.save()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("超过 20MB 的图片将不会被保存到历史中")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: 320)
    }

    // 隐私设置（暂时为空）
    @ViewBuilder
    private var privacySettings: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .padding(.top, 40)

            Text("隐私设置")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("即将推出更多隐私保护功能")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
