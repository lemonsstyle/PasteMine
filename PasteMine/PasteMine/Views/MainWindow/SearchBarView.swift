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
    let topApps: [AppSourceFilter] // 前2个最常用的应用
    let allApps: [AppSourceFilter]  // 所有应用（按次数排序）
    @State private var isHovered = false
    @State private var showAllApps = false
    @State private var iconCache: [String: NSImage] = [:] // 图标缓存

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("搜索...", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background {
                    if #available(macOS 14, *) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(isHovered ? 0.12 : 0.06),
                                    radius: isHovered ? 4 : 2,
                                    y: isHovered ? 2 : 1)
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
                
                // 筛选按钮组
                if !allApps.isEmpty {
                    HStack(spacing: 6) {
                        // "全部"按钮（文字版）
                        TextFilterButton(
                            title: "全部",
                            isSelected: selectedFilter == nil,
                            action: {
                                withAnimation(.smooth(duration: 0.2)) {
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
                                    withAnimation(.smooth(duration: 0.2)) {
                                        selectedFilter = app
                                        showAllApps = false
                                    }
                                }
                            )
                        }
                        
                        // "..."按钮
                        IconFilterButton(
                            icon: NSImage(systemSymbolName: "ellipsis", accessibilityDescription: nil) ?? NSImage(),
                            appName: "更多",
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
                                    withAnimation(.smooth(duration: 0.2)) {
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
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor : (isHovered ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.08)))
                }
        }
        .buttonStyle(.plain)
        .frame(height: 28)
        .help(title)
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.15)) {
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
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor : (isHovered ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.08)))
                }
        }
        .buttonStyle(.plain)
        .frame(width: 28, height: 28)
        .help(count != nil ? "\(appName) (\(count!) 条)" : appName)
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

