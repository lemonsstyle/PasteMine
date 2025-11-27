//
//  EmptyStateView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
                .symbolRenderingMode(.hierarchical)

            Text(message)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if #available(macOS 14, *) {
                Color.clear
                    .background(.ultraThinMaterial.opacity(0.5))
            } else {
                Color.clear
            }
        }
    }
}

#Preview {
    EmptyStateView(message: "暂无剪贴板历史")
}

