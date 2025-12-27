//
//  HistoryItemView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

struct HistoryItemView: View {
    let item: ClipboardItem
    var isSelected: Bool = false
    var showLockAnimation: Bool = false
    @State private var isHovered = false
    @State private var cachedImage: NSImage? = nil
    @State private var rotationAngle: Double = 0       // 旋转角度
    @State private var iconOpacity: Double = 1.0       // 固定图标透明度
    @State private var lockIconOpacity: Double = 0.0   // 锁图标透明度
    var onPinToggle: ((ClipboardItem) -> Void)?
    var onHoverChanged: ((Bool) -> Void)?

    private var displayContent: String {
        switch item.itemType {
        case .text:
            let lines = item.content?.components(separatedBy: .newlines) ?? []
            return lines.prefix(3).joined(separator: "\n")
        case .image:
            return "🖼️ \(AppText.Common.imageLabel) (\(item.imageWidth) × \(item.imageHeight))"
        }
    }

    private var timeAgo: String {
        guard let createdAt = item.createdAt else { return "" }
        return formatTimeAgo(from: createdAt)
    }

    /// 自定义时间格式化
    /// - 0~60秒 → "1分钟前"
    /// - 2~59分钟 → "X分钟前"
    /// - 1~23小时 → "X小时前"
    /// - 24小时及以上 → "X天前"
    private func formatTimeAgo(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        let seconds = Int(interval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24

        let isChinese = AppLanguage.current == .zhHans

        // 0~60秒 → "1分钟前"
        if seconds < 60 {
            return isChinese ? "1分钟前" : "1 min ago"
        }

        // 1分钟 → "1分钟前"
        if minutes == 1 {
            return isChinese ? "1分钟前" : "1 min ago"
        }

        // 2~59分钟 → "X分钟前"
        if minutes < 60 {
            return isChinese ? "\(minutes)分钟前" : "\(minutes) min ago"
        }

        // 1小时 → "1小时前"
        if hours == 1 {
            return isChinese ? "1小时前" : "1 hr ago"
        }

        // 2~23小时 → "X小时前"
        if hours < 24 {
            return isChinese ? "\(hours)小时前" : "\(hours) hr ago"
        }

        // 1天 → "1天前"
        if days == 1 {
            return isChinese ? "1天前" : "1 day ago"
        }

        // 2天及以上 → "X天前"
        return isChinese ? "\(days)天前" : "\(days) days ago"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // 左侧：内容/图片预览
                if item.itemType == .image {
                    // 显示图片缩略图
                    if let image = cachedImage ?? item.image {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(isHovered ? 0.15 : 0.08),
                                    radius: isHovered ? 4 : 2,
                                    y: isHovered ? 2 : 1)
                    } else {
                        // 图片加载失败，显示占位符
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.regularMaterial.opacity(0.5))
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.tertiary)
                            }
                    }
                }

                // 右侧：文本信息
                VStack(alignment: .leading, spacing: 4) {
                    if item.itemType == .text {
                        Text(displayContent)
                            .lineLimit(3)
                            .font(.body)
                            .foregroundStyle(.primary)
                    } else {
                        Text(displayContent)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    HStack {
                        Text(timeAgo)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let app = item.appSource, !app.isEmpty {
                            Text("· \(app)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()

                // Pin 按钮或锁图标
                Button(action: {
                    onPinToggle?(item)
                }) {
                    ZStack {
                        // 固定图标（带透明度）
                        Text("📌")
                            .font(.system(size: 14))
                            .foregroundColor(item.isPinned ? .blue : .secondary)
                            .opacity((isHovered || item.isPinned) ? iconOpacity : 0.0)

                        // 锁图标（带透明度和旋转）
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .rotationEffect(Angle(degrees: rotationAngle), anchor: .top)
                            .opacity(lockIconOpacity)
                    }
                    .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? AppText.Common.unpinned : AppText.Common.pinned)
                .onChange(of: showLockAnimation) { newValue in
                    if newValue {
                        performLockAnimation()
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .background {
                if isSelected || isHovered {
                    if #available(macOS 14, *) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.regularMaterial.opacity(isSelected ? 1.0 : 0.9))
                            .overlay {
                                // 微妙的光晕效果
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        RadialGradient(
                                            colors: [.white.opacity(isSelected ? 0.2 : 0.15), .clear],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 150
                                        )
                                    )
                            }
                            .shadow(color: .black.opacity(isSelected ? 0.15 : 0.12),
                                    radius: isSelected ? 8 : 6,
                                    y: isSelected ? 3 : 2)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(isSelected ? 0.7 : 0.5))
                    }
                }
            }
            .overlay {
                // 固定记录的浅蓝色边框
                if item.isPinned {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                }
            }
            .onHover { hovering in
                if hovering != isHovered {
                    withAnimation(.easeOut(duration: 0.12)) {
                        isHovered = hovering
                    }
                    onHoverChanged?(hovering)
                }
            }
            .onAppear {
                if cachedImage == nil, item.itemType == .image {
                    cachedImage = item.image
                }
            }

            // 分隔线
            if #available(macOS 14, *) {
                Divider()
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            } else {
                Divider()
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }
        }
    }

    // 执行简单的图标切换动画
    private func performLockAnimation() {
        // 阶段1: 固定图标淡出 (0.15s)
        withAnimation(.easeOut(duration: 0.15)) {
            iconOpacity = 0.0
        }

        // 阶段2: 锁图标淡入 (0.15s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeIn(duration: 0.15)) {
                lockIconOpacity = 1.0
            }
        }

        // 阶段3: 锁图标淡出 (开始于 0.5s，持续 0.15s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.15)) {
                lockIconOpacity = 0.0
            }
        }

        // 阶段4: 固定图标淡入 (开始于 0.65s，持续 0.15s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeIn(duration: 0.15)) {
                iconOpacity = 1.0
            }
        }
    }
}

