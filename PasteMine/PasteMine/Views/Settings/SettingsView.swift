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

// 隐私子分组枚举
enum PrivacySubGroup: String, CaseIterable {
    case apps = "忽略应用"
    case types = "忽略类型"
    
    var icon: String {
        switch self {
        case .apps: return "app.badge.fill"
        case .types: return "doc.text.fill"
        }
    }
}

struct SettingsView: View {
    @State private var settings = AppSettings.load()
    @State private var selectedGroup: SettingsGroup = .general
    @State private var selectedPrivacySubGroup: PrivacySubGroup = .apps
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
        .frame(width: 420, height: 521)
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
        VStack(spacing: 6) {
            SettingsSectionView(title: "") {
                HStack(spacing: 12) {
                    Text("通知")
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settings.notificationEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: settings.notificationEnabled) { _ in
                            settings.save()
                        }
                }
                
                Text("复制时显示通知")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)
            }

            SettingsSectionView(title: "") {
                HStack(spacing: 12) {
                    Text("音效")
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settings.soundEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: settings.soundEnabled) { _ in
                            settings.save()
                            if settings.soundEnabled {
                                SoundService.shared.playCopySound()
                            }
                        }
                }
                
                Text("播放提示音效")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)
            }
        }

        SettingsSectionView(title: "") {
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("全局快捷键")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    ShortcutRecorderView(shortcut: $settings.globalShortcut)
                        .onChange(of: settings.globalShortcut) { _ in
                            settings.save()
                        }
                    
                    Text("显示/隐藏窗口")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .padding(.vertical, 2)
                
                HStack(spacing: 12) {
                    Text("开机自启动")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settings.launchAtLogin)
                        .toggleStyle(.switch)
                        .onChange(of: settings.launchAtLogin) { newValue in
                            settings.save()
                            LaunchAtLoginService.shared.setLaunchAtLogin(enabled: newValue)
                        }
                }
                
                Text("自动启动应用")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)
            }
        }
    }

    // 存储设置
    @ViewBuilder
    private var storageSettings: some View {
        SettingsSectionView(title: "") {
            VStack(alignment: .leading, spacing: 3) {
                Text("历史记录上限")
                    .font(.body)
                    .foregroundStyle(.primary)
                
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

        SettingsSectionView(title: "") {
            HStack(spacing: 12) {
                Text("忽略大图片以节省磁盘空间")
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Toggle("", isOn: $settings.ignoreLargeImages)
                    .toggleStyle(.switch)
                    .onChange(of: settings.ignoreLargeImages) { _ in
                        settings.save()
                    }
            }
            
            Text("超过 20MB 的图片将不会被保存到历史中")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 1)
        }
    }

    // 隐私设置
    @ViewBuilder
    private var privacySettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 子分组选择器
            HStack(spacing: 8) {
                ForEach(PrivacySubGroup.allCases, id: \.self) { subGroup in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPrivacySubGroup = subGroup
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: subGroup.icon)
                                .font(.caption)
                            Text(subGroup.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(selectedPrivacySubGroup == subGroup ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedPrivacySubGroup == subGroup ? Color.accentColor : Color.secondary.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 4)
            
            // 子分组内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    switch selectedPrivacySubGroup {
                    case .apps:
                        appsSubGroup
                    case .types:
                        typesSubGroup
                    }
                }
            }
            .frame(height: 157)
            
            Divider()
                .padding(.vertical, 2)
            
            // 底部：退出时清空开关（始终显示）
            clearOnQuitSection
                .padding(.top, 2)
        }
    }
    
    // 忽略应用子分组
    @ViewBuilder
    private var appsSubGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppPickerView(
                apps: $settings.ignoredApps,
                title: "应用列表",
                helpText: "这些应用中的复制操作不会被记录"
            )
            .onChange(of: settings.ignoredApps) { _ in
                settings.save()
            }
        }
        .padding(8)
    }
    
    // 忽略类型子分组
    @ViewBuilder
    private var typesSubGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            EditableListView(
                items: $settings.ignoredPasteboardTypes,
                title: "类型列表",
                placeholder: "输入 pasteboard type",
                helpText: "这些类型的内容不会被记录（如密码、临时数据）"
            )
            .onChange(of: settings.ignoredPasteboardTypes) { _ in
                settings.save()
            }
        }
        .padding(8)
    }
    
    // 退出时清空部分（始终显示在底部）
    @ViewBuilder
    private var clearOnQuitSection: some View {
        SettingsSectionView(title: "") {
            HStack(spacing: 12) {
                Text("退出时清空剪贴板")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Toggle("", isOn: $settings.clearOnQuit)
                    .toggleStyle(.switch)
                    .onChange(of: settings.clearOnQuit) { _ in
                        settings.save()
                    }
            }
            
            Text("退出应用时自动清除所有历史记录")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 1)
        }
        .frame(maxWidth: 320)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            content
        }
        .padding(8)
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
