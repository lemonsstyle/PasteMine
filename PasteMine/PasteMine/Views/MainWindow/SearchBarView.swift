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
    let count: Int
    
    static let all = AppSourceFilter(appName: "", count: 0) // 特殊值表示"全部"
    
    static func == (lhs: AppSourceFilter, rhs: AppSourceFilter) -> Bool {
        lhs.appName == rhs.appName
    }
    
    // 获取应用图标
    var icon: NSImage {
        guard !appName.isEmpty else {
            return NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: nil) ?? NSImage()
        }
        
        // 尝试通过应用名称查找应用路径
        let workspace = NSWorkspace.shared
        
        // 常见应用路径
        let appPaths = [
            "/Applications/\(appName).app",
            "/System/Applications/\(appName).app",
            "/Applications/Utilities/\(appName).app"
        ]
        
        for path in appPaths {
            if FileManager.default.fileExists(atPath: path) {
                return workspace.icon(forFile: path)
            }
        }
        
        // 如果找不到，使用默认图标
        return NSImage(systemSymbolName: "app", accessibilityDescription: nil) ?? NSImage()
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
                        // "全部"按钮
                        FilterButton(
                            icon: NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: nil) ?? NSImage(),
                            count: nil,
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
                            FilterButton(
                                icon: getIcon(for: app.appName),
                                count: app.count,
                                isSelected: selectedFilter?.appName == app.appName,
                                action: {
                                    withAnimation(.smooth(duration: 0.2)) {
                                        selectedFilter = app
                                        showAllApps = false
                                    }
                                }
                            )
                        }
                        
                        // "..."按钮
                        FilterButton(
                            icon: NSImage(systemSymbolName: "ellipsis", accessibilityDescription: nil) ?? NSImage(),
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
                            FilterButton(
                                icon: getIcon(for: app.appName),
                                count: app.count,
                                isSelected: selectedFilter?.appName == app.appName,
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
                .frame(height: 36)
            }
        }
    }
    
    // 获取应用图标（带缓存）
    private func getIcon(for appName: String) -> NSImage {
        if let cached = iconCache[appName] {
            return cached
        }
        
        let workspace = NSWorkspace.shared
        var icon: NSImage?
        
        // 常见应用路径
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
}

// 筛选按钮组件（图标版）
struct FilterButton: View {
    let icon: NSImage
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                
                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 9))
                        .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : (isHovered ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.08)))
            }
        }
        .buttonStyle(.plain)
        .help(count != nil ? "筛选 (\(count!) 条)" : "")
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

