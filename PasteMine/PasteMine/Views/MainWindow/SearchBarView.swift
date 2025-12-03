//
//  SearchBarView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

struct AppSourceFilter: Equatable {
    let appName: String
    let count: Int
    
    static let all = AppSourceFilter(appName: "", count: 0) // 特殊值表示"全部"
    
    static func == (lhs: AppSourceFilter, rhs: AppSourceFilter) -> Bool {
        lhs.appName == rhs.appName
    }
}

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var selectedFilter: AppSourceFilter?
    let topApps: [AppSourceFilter] // 前2个最常用的应用
    let allApps: [AppSourceFilter]  // 所有应用（按次数排序）
    @State private var isHovered = false
    @State private var showAllApps = false

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
                            FilterButton(
                                title: app.appName,
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
                            title: "...",
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
                                title: app.appName,
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
                .frame(height: 32)
            }
        }
    }
}

// 筛选按钮组件
struct FilterButton: View {
    let title: String
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                
                if let count = count {
                    Text("(\(count))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : (isHovered ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.08)))
            }
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

