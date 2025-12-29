//
//  SearchBarView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI
import AppKit

struct AppSourceFilter: Equatable {
    let appName: String
    let bundleId: String?
    let count: Int
    
    static let all = AppSourceFilter(appName: "", bundleId: nil, count: 0) // 特殊值表示"全部"
    
    static func == (lhs: AppSourceFilter, rhs: AppSourceFilter) -> Bool {
        // 优先用 bundleId 匹配，如果都没有则用 appName
        if let lhsId = lhs.bundleId, let rhsId = rhs.bundleId {
            return lhsId == rhsId
        }
        return lhs.appName == rhs.appName
    }
}

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var selectedFilter: AppSourceFilter?
    @Binding var showProSheet: Bool
    @Binding var isSourceFilterTooltipVisible: Bool  // 来源筛选气泡提示显示状态
    let topApps: [AppSourceFilter] // 前2个最常用的应用
    let allApps: [AppSourceFilter]  // 所有应用（按次数排序）
    // 键盘事件回调
    var onArrowUp: () -> Void = {}
    var onArrowDown: () -> Void = {}
    var onEnter: () -> Void = {}
    var onEscape: () -> Void = {}

    @State private var isHovered = false
    @State private var showAllApps = false
    @State private var iconCache: [String: NSImage] = [:] // 图标缓存
    @EnvironmentObject private var proManager: ProEntitlementManager

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    FocusableSearchField(
                        text: $searchText,
                        placeholder: AppText.MainWindow.searchPlaceholder,
                        onArrowUp: onArrowUp,
                        onArrowDown: onArrowDown,
                        onEnter: onEnter,
                        onEscape: onEscape
                    )

                    if !searchText.isEmpty {
                        Button(action: {
                            withAnimation(DesignSystem.Animation.easeOut()) {
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(8)
                .background {
                    if #available(macOS 14, *) {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(.regularMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                            }
                            .applyShadow(DesignSystem.Shadow.medium(isHovered: isHovered))
                    } else {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(Color(NSColor.controlBackgroundColor))
                    }
                }
                .onHover { hovering in
                    withAnimation(DesignSystem.Animation.easeInOut()) {
                        isHovered = hovering
                    }
                }
                
                // 筛选按钮组
                if !allApps.isEmpty {
                    HStack(spacing: 6) {
                        // "全部"按钮（文字版）
                        TextFilterButton(
                            title: AppText.MainWindow.filterAll,
                            isSelected: selectedFilter == nil,
                            action: {
                                withAnimation(DesignSystem.Animation.easeInOut()) {
                                    selectedFilter = nil
                                    showAllApps = false
                                }
                            }
                        )
                        
                        // 前2个最常用的应用
                        ForEach(topApps.prefix(2), id: \.appName) { app in
                            IconFilterButton(
                                icon: getIconByBundleId(app.bundleId),
                                appName: app.appName,
                                count: app.count,
                                isSelected: selectedFilter == app,
                                action: {
                                    // 🎉 所有用户都可以使用来源筛选功能
                                    withAnimation(DesignSystem.Animation.easeInOut()) {
                                        selectedFilter = app
                                        showAllApps = false
                                    }
                                }
                            )
                        }
                        
                        // "..."按钮
                        IconFilterButton(
                            icon: NSImage(systemSymbolName: "ellipsis", accessibilityDescription: nil) ?? NSImage(),
                            appName: AppText.MainWindow.filterMore,
                            count: nil,
                            isSelected: showAllApps,
                            action: {
                                withAnimation(.smooth(duration: 0.2)) {
                                    showAllApps.toggle()
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // 展开的所有应用列表
            if showAllApps && !allApps.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(allApps, id: \.appName) { app in
                            IconFilterButton(
                                icon: getIconByBundleId(app.bundleId),
                                appName: app.appName,
                                count: app.count,
                                isSelected: selectedFilter == app,
                                action: {
                                    // 🎉 所有用户都可以使用来源筛选功能
                                    withAnimation(DesignSystem.Animation.easeInOut()) {
                                        selectedFilter = app
                                        showAllApps = false
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 34)
            }
        }
    }

    // 显示来源筛选限制弹窗或气泡提示
    private func showSourceFilterAlert() {
        var settings = AppSettings.load()

        // 如果用户已选择"不再显示"，则显示气泡提示
        if settings.hideSourceFilterAlert {
            showSourceFilterTooltip()
            return
        }

        // 否则显示完整弹窗
        let alert = NSAlert()
        alert.messageText = L10n.text("升级到 Pro 解锁来源分类", "Upgrade to Pro to unlock source filtering")
        alert.informativeText = L10n.text("为复制内容添加 浏览器 / 微信 / 备忘录等分类，查找复制更有条理。", "Categorize content by Browser / WeChat / Notes for more organized search.")
        alert.alertStyle = .informational
        alert.addButton(withTitle: AppText.Pro.upgradeToPro)
        alert.addButton(withTitle: AppText.Common.cancel)

        // 添加"不再显示"勾选框
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = L10n.text("不再显示", "Don't show this again")

        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window) { [self] response in
                // 保存"不再显示"选项
                if alert.suppressionButton?.state == .on {
                    var updatedSettings = AppSettings.load()
                    updatedSettings.hideSourceFilterAlert = true
                    updatedSettings.save()
                }

                if response == .alertFirstButtonReturn {
                    // 打开 Pro 面板
                    showProSheet = true
                }
            }
        } else {
            let response = alert.runModal()

            // 保存"不再显示"选项
            if alert.suppressionButton?.state == .on {
                var updatedSettings = AppSettings.load()
                updatedSettings.hideSourceFilterAlert = true
                updatedSettings.save()
            }

            if response == .alertFirstButtonReturn {
                // 打开 Pro 面板
                showProSheet = true
            }
        }
    }

    // 显示来源筛选限制气泡提示
    private func showSourceFilterTooltip() {
        isSourceFilterTooltipVisible = true
        // 2秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSourceFilterTooltipVisible = false
        }
    }
    
    // 获取应用图标（带缓存）- 通过应用名查找
    private func getIcon(for appName: String) -> NSImage {
        if let cached = iconCache[appName] {
            return cached
        }
        
        // 首先尝试通过 Bundle ID 获取图标
        // 因为 appName 实际上是 displayName，不一定能找到应用包
        let workspace = NSWorkspace.shared
        var icon: NSImage?
        
        // 常见应用路径模式
        let appPaths = [
            "/Applications/\(appName).app",
            "/System/Applications/\(appName).app",
            "/Applications/Utilities/\(appName).app"
        ]
        
        for path in appPaths {
            if FileManager.default.fileExists(atPath: path) {
                icon = workspace.icon(forFile: path)
                break
            }
        }
        
        // 如果找不到，使用默认图标
        let finalIcon = icon ?? (NSImage(systemSymbolName: "app", accessibilityDescription: nil) ?? NSImage())
        iconCache[appName] = finalIcon
        return finalIcon
    }
    
    // 通过 Bundle ID 获取应用图标
    private func getIconByBundleId(_ bundleId: String?) -> NSImage {
        guard let bundleId = bundleId, !bundleId.isEmpty else {
            return NSImage(systemSymbolName: "app", accessibilityDescription: nil) ?? NSImage()
        }
        
        // 检查缓存
        if let cached = iconCache[bundleId] {
            return cached
        }
        
        let workspace = NSWorkspace.shared
        var icon: NSImage?
        
        // 通过 Bundle ID 获取应用路径
        if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleId) {
            icon = workspace.icon(forFile: appURL.path)
        }
        
        // 如果找不到，使用默认图标
        let finalIcon = icon ?? (NSImage(systemSymbolName: "app", accessibilityDescription: nil) ?? NSImage())
        iconCache[bundleId] = finalIcon
        return finalIcon
    }
}

// 文字筛选按钮（用于"全部"）
struct TextFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .fill(isSelected ? Color.accentColor : (isHovered ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.08)))
                }
        }
        .buttonStyle(.plain)
        .frame(height: 28)
        .help(title)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.easeOut()) {
                isHovered = hovering
            }
        }
    }
}

// 图标筛选按钮（用于应用）
struct IconFilterButton: View {
    let icon: NSImage
    let appName: String
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
                .padding(3)
                .background {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .fill(isSelected ? Color.accentColor : (isHovered ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.08)))
                }
        }
        .buttonStyle(.plain)
        .frame(width: 28, height: 28)
        .help(count != nil ? "\(appName) (\(count!) \(L10n.text("条", "items")))" : appName)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.easeOut()) {
                isHovered = hovering
            }
        }
    }
}


// 来源筛选限制气泡提示视图
struct SourceFilterTooltipView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .foregroundColor(.blue)
                .font(.system(size: 14))

            Text(L10n.text("升级到 Pro 解锁来源分类", "Upgrade to Pro to unlock source filtering"))
                .font(.system(size: 13))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: - 可聚焦的搜索框（支持键盘导航）

/// 自定义搜索框，支持自动聚焦和键盘事件拦截
struct FocusableSearchField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onArrowUp: () -> Void
    var onArrowDown: () -> Void
    var onEnter: () -> Void
    var onEscape: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = .systemFont(ofSize: 13)
        textField.cell?.lineBreakMode = .byTruncatingTail

        // 监听窗口显示通知，自动聚焦
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )

        // 保存 textField 引用
        context.coordinator.textField = textField

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate, NSControlTextEditingDelegate {
        var parent: FocusableSearchField
        weak var textField: NSTextField?

        init(_ parent: FocusableSearchField) {
            self.parent = parent
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc func windowDidBecomeKey(_ notification: Notification) {
            // 窗口激活时，让搜索框获得焦点
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let textField = self?.textField else { return }
                textField.window?.makeFirstResponder(textField)
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        // 拦截特定按键命令
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.moveUp(_:)):
                // 上箭头
                parent.onArrowUp()
                return true
            case #selector(NSResponder.moveDown(_:)):
                // 下箭头
                parent.onArrowDown()
                return true
            case #selector(NSResponder.insertNewline(_:)):
                // 回车
                parent.onEnter()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                // Esc
                parent.onEscape()
                return true
            default:
                return false
            }
        }
    }
}

// 通知名称：请求搜索框聚焦
extension Notification.Name {
    static let focusSearchField = Notification.Name("focusSearchField")
}
