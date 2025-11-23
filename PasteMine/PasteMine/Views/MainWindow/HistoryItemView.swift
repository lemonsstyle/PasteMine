//
//  HistoryItemView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

struct HistoryItemView: View {
    let item: ClipboardItem
    
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
        HStack(alignment: .top, spacing: 12) {
            // 左侧：内容/图片预览
            if item.itemType == .image {
                // 显示图片缩略图
                if let image = item.image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                } else {
                    // 图片加载失败，显示占位符
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
            }
            
            // 右侧：文本信息
            VStack(alignment: .leading, spacing: 4) {
                if item.itemType == .text {
                    Text(displayContent)
                        .lineLimit(3)
                        .font(.body)
                } else {
                    Text(displayContent)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let app = item.appSource, !app.isEmpty {
                        Text("· \(app)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

