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
            Text(AppText.Settings.title)
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
                Button(AppText.Settings.doneButton) {
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
        VStack(spacing: 5) {
            SettingsSectionView(title: "") {
                HStack(spacing: 12) {
                    Text(AppText.Settings.General.notification)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $settings.notificationEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: settings.notificationEnabled) { _ in
                            settings.save()
                        }
                }
                
                Text(AppText.Settings.General.notificationDesc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)
            }

            SettingsSectionView(title: "") {
                HStack(spacing: 12) {
                    Text(AppText.Settings.General.sound)
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
                
                Text(AppText.Settings.General.soundDesc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)
            }
        }

        SettingsSectionView(title: "") {
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(AppText.Settings.General.globalShortcut)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    ShortcutRecorderView(shortcut: $settings.globalShortcut)
                        .onChange(of: settings.globalShortcut) { _ in
                            settings.save()
                        }
                    
                    Text(AppText.Settings.General.globalShortcutDesc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .padding(.vertical, 1)
                
                HStack(spacing: 12) {
                    Text(AppText.Settings.General.launchAtLogin)
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
                
                Text(AppText.Settings.General.launchAtLoginDesc)
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
                Text(AppText.Settings.Storage.historyLimit)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Picker("", selection: $settings.maxHistoryCount) {
                    ForEach(AppSettings.historyCountOptions, id: \.self) { count in
                        Text(count == 999 ? AppText.Settings.Storage.historyPermanent : AppText.Settings.Storage.historyCount(count)).tag(count)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: settings.maxHistoryCount) { _ in
                    settings.save()
                }

                Text(AppText.Settings.Storage.historyLimitDesc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }

        SettingsSectionView(title: "") {
            HStack(spacing: 12) {
                Text(AppText.Settings.Storage.ignoreLargeImages)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Toggle("", isOn: $settings.ignoreLargeImages)
                    .toggleStyle(.switch)
                    .onChange(of: settings.ignoreLargeImages) { _ in
                        settings.save()
                    }
            }
            
            Text(AppText.Settings.Storage.ignoreLargeImagesDesc)
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
            VStack(alignment: .leading, spacing: 10) {
                switch selectedPrivacySubGroup {
                case .apps:
                    appsSubGroup
                case .types:
                    typesSubGroup
                }
            }
            
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
                title: AppText.Settings.Privacy.typeListTitle,
                helpText: AppText.Settings.Privacy.ignoreAppsDesc
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
                title: AppText.Settings.Privacy.typeListTitle,
                placeholder: AppText.Settings.Privacy.typePlaceholder,
                helpText: AppText.Settings.Privacy.ignoreTypesDesc,
                toggleBinding: $settings.ignoreTypesEnabled,
                toggleLabel: AppText.Settings.Privacy.ignoreTypesToggleLabel
            )
            .onChange(of: settings.ignoredPasteboardTypes) { _ in
                settings.save()
            }
            .onChange(of: settings.ignoreTypesEnabled) { _ in
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
                Text(AppText.Settings.Privacy.clearOnQuit)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Toggle("", isOn: $settings.clearOnQuit)
                    .toggleStyle(.switch)
                    .onChange(of: settings.clearOnQuit) { _ in
                        settings.save()
                    }
            }
            
            Text(AppText.Settings.Privacy.clearOnQuitDesc)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 1)
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
