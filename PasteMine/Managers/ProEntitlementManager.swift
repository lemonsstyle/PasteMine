//
//  ProEntitlementManager.swift
//  PasteMine
//
//  Created by lagrange on 2025/12/08.
//

import Foundation
import Combine

/// Pro 会员状态枚举
enum ProState: Equatable {
    case free                                   // 免费版
    case trialActive(daysLeft: Int)             // 正在免费体验，还剩几天
    case trialExpired                           // 体验结束，已回退到免费版
    case purchased                              // 已付费购买 Pro
}

/// Pro 会员权限管理器
@MainActor
class ProEntitlementManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ProEntitlementManager()
    
    // MARK: - Published Properties
    
    /// 当前 Pro 状态（只读）
    @Published private(set) var state: ProState = .free
    
    /// 是否因为试用到期需要弹出 Pro 面板
    @Published var shouldShowProSheetBecauseTrialExpired = false
    
    // MARK: - UserDefaults Keys
    
    private let keyProPurchased = "PasteMine_ProPurchased"
    private let keyTrialStartDate = "PasteMine_TrialStartDate"
    private let keyTrialUsedOnce = "PasteMine_TrialUsedOnce"
    private let keyTrialExpiredNotified = "PasteMine_TrialExpiredNotified"  // 新增：记录是否已通知试用到期
    
    // MARK: - Computed Properties

    /// Pro 功能是否可用（所有用户免费使用，始终返回 true）
    var isProFeatureEnabled: Bool {
        return true  // 🎉 所有功能免费开放
    }
    
    /// 是否已经使用过试用
    var hasUsedTrial: Bool {
        UserDefaults.standard.bool(forKey: keyTrialUsedOnce)
    }
    
    // MARK: - Initialization
    
    private init() {
        recalcState()
    }
    
    // MARK: - State Management
    
    /// 重新计算状态
    func recalcState() {
        let previousState = state
        
        // 1. 检查是否已购买
        let isPurchased = UserDefaults.standard.bool(forKey: keyProPurchased)
        if isPurchased {
            state = .purchased
            print("✅ Pro 状态: 已购买")
            return
        }
        
        // 2. 检查试用状态
        if let trialStartDate = UserDefaults.standard.object(forKey: keyTrialStartDate) as? Date {
            let elapsed = Calendar.current.dateComponents([.day], from: trialStartDate, to: Date()).day ?? 0

            if elapsed >= 7 {
                // 试用已过期
                state = .trialExpired
                print("⏰ Pro 状态: 试用已过期")

                // 🔧 Bug Fix 2: 试用到期时自动关闭图片预览
                var settings = AppSettings.load()
                if settings.imagePreviewEnabled {
                    settings.imagePreviewEnabled = false
                    settings.save()
                    print("🔧 已自动关闭图片预览功能（试用到期）")
                }

                // 🔧 Bug Fix 3: 持久化试用到期通知标志
                let hasNotified = UserDefaults.standard.bool(forKey: keyTrialExpiredNotified)
                if !hasNotified {
                    // 如果还没有通知过，设置标志并触发通知
                    shouldShowProSheetBecauseTrialExpired = true
                    UserDefaults.standard.set(true, forKey: keyTrialExpiredNotified)
                    print("🔔 设置试用到期提醒标志")
                } else if case .trialActive = previousState {
                    // 如果之前是试用中，现在刚过期（即使已经通知过），也要再次提醒
                    shouldShowProSheetBecauseTrialExpired = true
                    print("🔔 试用刚过期，再次提醒用户")
                }
            } else {
                // 试用中
                let daysLeft = 7 - elapsed
                state = .trialActive(daysLeft: daysLeft)
                print("🎉 Pro 状态: 试用中（还剩 \(daysLeft) 天）")
            }
            return
        }
        
        // 3. 默认免费版
        state = .free
        print("ℹ️ Pro 状态: 免费版")
    }
    
    // MARK: - Trial Management
    
    /// 开始免费试用
    func startFreeTrial() {
        // 检查是否已购买
        if case .purchased = state {
            print("⚠️ 已购买用户无需试用")
            return
        }

        // 检查是否已使用过试用
        if hasUsedTrial {
            print("⚠️ 试用已使用过，无法再次试用")
            return
        }

        // 开始试用
        UserDefaults.standard.set(Date(), forKey: keyTrialStartDate)
        UserDefaults.standard.set(true, forKey: keyTrialUsedOnce)

        // 启用图片悬停预览
        var settings = AppSettings.load()
        settings.imagePreviewEnabled = true
        settings.save()

        recalcState()
        print("🎉 开始免费试用 7 天，已启用图片预览功能")
    }
    
    // MARK: - Purchase Management
    
    /// 标记为已购买（供 PurchaseManager 调用）
    func markPurchased() {
        UserDefaults.standard.set(true, forKey: keyProPurchased)
        state = .purchased
        shouldShowProSheetBecauseTrialExpired = false  // 清除弹窗标记

        // 启用图片悬停预览
        var settings = AppSettings.load()
        settings.imagePreviewEnabled = true
        settings.save()

        print("✅ Pro 已激活: 已购买，已启用图片预览功能")
    }
    
    /// 设置为已购买状态（兼容旧接口）
    func setPurchased() {
        markPurchased()
    }
    
    /// 重置所有状态（用于测试）
    func resetToFree() {
        UserDefaults.standard.set(false, forKey: keyProPurchased)
        UserDefaults.standard.removeObject(forKey: keyTrialStartDate)
        UserDefaults.standard.set(false, forKey: keyTrialUsedOnce)
        state = .free
        shouldShowProSheetBecauseTrialExpired = false
        print("ℹ️ Pro 已重置: 免费版（包括试用状态）")
    }
}

