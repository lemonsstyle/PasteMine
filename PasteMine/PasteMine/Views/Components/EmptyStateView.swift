//
//  EmptyStateView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

struct EmptyStateView: View {
    let message: String
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // 带呼吸动画的图标
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
                .symbolRenderingMode(.hierarchical)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .opacity(isAnimating ? 0.8 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(getHintText())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if #available(macOS 14, *) {
                Color.clear
                    .background(.ultraThinMaterial.opacity(0.3))
            } else {
                Color.clear
            }
        }
        .onAppear {
            isAnimating = true
        }
    }

    private func getHintText() -> String {
        if message.contains("暂无") || message.lowercased().contains("no") {
            return AppLanguage.current == .zhHans
                ? "复制任何内容开始使用"
                : "Copy anything to get started"
        } else {
            return AppLanguage.current == .zhHans
                ? "尝试其他搜索词"
                : "Try different search terms"
        }
    }
}

#Preview {
    EmptyStateView(message: "暂无剪贴板历史")
}

