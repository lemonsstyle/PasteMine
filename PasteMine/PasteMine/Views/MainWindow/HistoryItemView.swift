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
    @State private var isHovered = false
    var onPinToggle: ((ClipboardItem) -> Void)?

    private var displayContent: String {
        switch item.itemType {
        case .text:
            let lines = item.content?.components(separatedBy: .newlines) ?? []
            return lines.prefix(3).joined(separator: "\n")
        case .image:
            return "🖼️ 图片 (\(item.imageWidth) × \(item.imageHeight))"
        }
    }

    private var timeAgo: String {
        guard let createdAt = item.createdAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // 左侧：内容/图片预览
                if item.itemType == .image {
                    // 显示图片缩略图
                    if let image = item.image {
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

                // Pin 按钮
                Button(action: {
                    onPinToggle?(item)
                }) {
                    Text("📌")
                        .font(.system(size: 14))
                        .foregroundColor(item.isPinned ? .blue : .secondary)
                        .opacity((isHovered || item.isPinned) ? 1.0 : 0.0)
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "取消固定" : "固定")
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
                withAnimation(.smooth(duration: 0.25)) {
                    isHovered = hovering
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
}

