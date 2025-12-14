//
//  ProSheetView.swift
//  PasteMine
//
//  Created by lagrange on 2025/12/08.
//

import SwiftUI

/// Pro 面板进入上下文
enum ProEntryContext: Equatable {
    case normal                         // 用户手动点击 Pro 入口
    case trialActive(remainingDays: Int) // 试用中
    case trialExpired                   // 试用刚过期
    case purchased                      // 已购买
}

struct ProSheetView: View {
    let context: ProEntryContext
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var proManager: ProEntitlementManager
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var isPurchasing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(context: ProEntryContext? = nil) {
        // 如果没有传入上下文，根据当前状态自动判断
        if let context = context {
            self.context = context
        } else {
            let state = ProEntitlementManager.shared.state
            switch state {
            case .free:
                self.context = .normal
            case .trialActive(let daysLeft):
                self.context = .trialActive(remainingDays: daysLeft)
            case .trialExpired:
                self.context = .trialExpired
            case .purchased:
                self.context = .purchased
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 顶部标题区域
            HStack(alignment: .top) {
                Text(AppText.Pro.sheetTitle)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // 关闭按钮
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help(AppText.Common.close)
            }
            
            Divider()
            
            // 上下文相关的提示条
            contextBanner
                .padding(.vertical, context == .normal ? 0 : 4)
            
            // 提示标签
            Label {
                Text(AppText.Pro.upgradeExperience)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.accentColor)
            }
            
            // 特性卡片网格
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ProFeatureCard(
                    iconName: "clock.arrow.circlepath",
                    title: AppText.Pro.Features.longerHistoryTitle,
                    subtitle: AppText.Pro.Features.longerHistoryDesc
                )
                
                ProFeatureCard(
                    iconName: "photo.on.rectangle",
                    title: AppText.Pro.Features.hoverPreviewTitle,
                    subtitle: AppText.Pro.Features.hoverPreviewDesc
                )
                
                ProFeatureCard(
                    iconName: "tag",
                    title: AppText.Pro.Features.sourceTagsTitle,
                    subtitle: AppText.Pro.Features.sourceTagsDesc
                )
                
                ProFeatureCard(
                    iconName: "pin.fill",
                    title: AppText.Pro.Features.unlimitedPinsTitle,
                    subtitle: AppText.Pro.Features.unlimitedPinsDesc
                )
            }
            
            Spacer()
                .frame(height: 8)
            
            // 底部操作区
            VStack(spacing: 8) {
                // 免费试用按钮（仅在免费版且未使用过试用时显示）
                if case .normal = context, case .free = proManager.state, !proManager.hasUsedTrial {
                    Button(action: {
                        proManager.startFreeTrial()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "gift.fill")
                            Text(AppText.Pro.freeTrialButton)
                        }
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.orange)
                    
                    Text(AppText.Pro.or)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // 主购买按钮
                if context != .purchased {
                    Button(action: {
                        handlePurchase()
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                            }
                            Text(mainButtonTitle)
                        }
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isPurchasing)
                    
                    // 购买说明
                    Text(AppText.Pro.oneTimePurchase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    // 已购买状态
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(AppText.Pro.alreadyPurchased)
                            .font(.body.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green.opacity(0.1))
                    )
                }
                
                // 辅助按钮
                HStack(spacing: 16) {
                    if context != .purchased {
                        Button(action: {
                            handleRestore()
                        }) {
                            Text(AppText.Pro.restorePurchase)
                        }
                        .buttonStyle(.link)
                        .disabled(isPurchasing)
                    }
                    
                    Button(action: {
                        openFeedback()
                    }) {
                        Text(AppText.Pro.sendFeedback)
                    }
                    .buttonStyle(.link)
                    
                    // 试用过期时显示"继续使用免费版"
                    if case .trialExpired = context {
                        Button(action: {
                            dismiss()
                        }) {
                            Text(AppText.Pro.continueFreePlan)
                        }
                        .buttonStyle(.link)
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 480)
        .background {
            if #available(macOS 14, *) {
                Color.clear
                    .background(.ultraThinMaterial)
            } else {
                Color(NSColor.windowBackgroundColor)
            }
        }
        .alert(AppText.Pro.alertTitle, isPresented: $showAlert) {
            Button(AppText.Common.ok, role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onChange(of: purchaseManager.purchaseState) { state in
            handlePurchaseStateChange(state)
        }
    }
    
    // MARK: - Computed Properties
    
    /// 主按钮标题
    private var mainButtonTitle: String {
        switch context {
        case .normal:
            return AppText.Pro.purchaseButton
        case .trialActive:
            return AppText.Pro.purchaseButtonTrial
        case .trialExpired:
            return AppText.Pro.purchaseButtonExpired
        case .purchased:
            return AppText.Pro.alreadyPurchased
        }
    }
    
    /// 上下文相关的横幅提示
    @ViewBuilder
    private var contextBanner: some View {
        switch context {
        case .trialActive(let remainingDays):
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .foregroundStyle(.orange)
                Text(AppText.Pro.trialActiveBanner(daysLeft: remainingDays))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
            )
            
        case .trialExpired:
            HStack(spacing: 8) {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundStyle(.red)
                Text(AppText.Pro.trialExpiredBanner)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.1))
            )
            
        case .purchased:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text(AppText.Pro.purchasedBanner)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.1))
            )
            
        case .normal:
            EmptyView()
        }
    }
    
    // MARK: - Actions
    
    private func handlePurchase() {
        isPurchasing = true
        Task {
            await purchaseManager.purchasePro()
        }
    }
    
    private func handleRestore() {
        isPurchasing = true
        Task {
            await purchaseManager.restorePurchases()
        }
    }
    
    private func handlePurchaseStateChange(_ state: PurchaseManager.PurchaseState) {
        isPurchasing = false
        
        switch state {
        case .success:
            alertMessage = AppText.Pro.purchaseSuccess
            showAlert = true
            // 延迟关闭面板
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
            
        case .restored:
            alertMessage = AppText.Pro.restoreSuccess
            showAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
            
        case .failed(let errorMessage):
            alertMessage = AppText.Pro.purchaseFailed(error: errorMessage)
            showAlert = true
            
        case .idle, .purchasing:
            break
        }
    }
    
    private func openFeedback() {
        // TODO: 实现反馈功能（例如打开邮件或反馈表单）
        if let url = URL(string: "mailto:support@pastemine.app?subject=PasteMine Pro 反馈") {
            NSWorkspace.shared.open(url)
        }
    }
}

/// Pro 特性卡片组件
struct ProFeatureCard: View {
    let iconName: String
    let title: String
    let subtitle: String
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 图标
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundStyle(Color.accentColor)
            
            // 标题
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            
            // 副标题
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            if #available(macOS 14, *) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(isHovered ? 0.12 : 0.06),
                            radius: isHovered ? 6 : 3,
                            y: isHovered ? 3 : 1)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            }
        }
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    ProSheetView()
}

