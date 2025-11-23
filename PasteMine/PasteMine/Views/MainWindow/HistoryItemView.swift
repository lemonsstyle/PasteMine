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
        let lines = item.content?.components(separatedBy: .newlines) ?? []
        return lines.prefix(3).joined(separator: "\n")
    }
    
    private var timeAgo: String {
        guard let createdAt = item.createdAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(displayContent)
                .lineLimit(3)
                .font(.body)
            
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
        .padding(.vertical, 4)
    }
}

