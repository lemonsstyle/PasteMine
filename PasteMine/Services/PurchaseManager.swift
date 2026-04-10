//
//  PurchaseManager.swift
//  PasteMine
//
//  Created by lagrange on 2025/12/08.
//

import Foundation
import StoreKit
import Combine

/// IAP 购买管理器
@MainActor
class PurchaseManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PurchaseManager()
    
    // MARK: - Product ID
    private let proProductID = "pasteMine.pro.lifetime"
    
    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseState: PurchaseState = .idle
    
    // MARK: - Purchase State
    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case success
        case failed(String)  // 使用 String 存储错误信息，以支持 Equatable
        case restored
    }
    
    // MARK: - Initialization
    private init() {
        Task {
            await loadProducts()
            await checkPurchaseStatus()
        }
    }
    
    // MARK: - Product Loading
    
    /// 加载产品信息
    private func loadProducts() async {
        do {
            let products = try await Product.products(for: [proProductID])
            self.products = products
            print("✅ StoreKit: 已加载 \(products.count) 个产品")
        } catch {
            print("❌ StoreKit: 加载产品失败 - \(error)")
        }
    }
    
    // MARK: - Purchase
    
    /// 购买 Pro
    func purchasePro() async {
        guard let product = products.first else {
            print("❌ StoreKit: 产品未加载")
            purchaseState = .failed(AppText.PurchaseError.productNotLoaded)
            return
        }
        
        purchaseState = .purchasing
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 验证交易
                let transaction = try checkVerified(verification)
                
                // 更新权限状态
                await ProEntitlementManager.shared.markPurchased()
                
                // 完成交易
                await transaction.finish()
                
                purchaseState = .success
                print("✅ StoreKit: 购买成功")
                
            case .userCancelled:
                purchaseState = .idle
                print("ℹ️ StoreKit: 用户取消购买")
                
            case .pending:
                purchaseState = .idle
                print("⏳ StoreKit: 购买等待中")
                
            @unknown default:
                purchaseState = .idle
                print("⚠️ StoreKit: 未知购买状态")
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            print("❌ StoreKit: 购买失败 - \(error)")
        }
    }
    
    /// 恢复购买
    func restorePurchases() async {
        purchaseState = .purchasing
        
        do {
            // 同步最新的交易状态
            try await AppStore.sync()
            
            // 检查购买状态
            await checkPurchaseStatus()
            
            if ProEntitlementManager.shared.state == .purchased {
                purchaseState = .restored
                print("✅ StoreKit: 恢复购买成功")
            } else {
                purchaseState = .idle
                print("ℹ️ StoreKit: 未找到购买记录")
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            print("❌ StoreKit: 恢复购买失败 - \(error)")
        }
    }
    
    // MARK: - Purchase Status Check
    
    /// 检查购买状态
    private func checkPurchaseStatus() async {
        var hasPurchased = false
        
        // 遍历所有未完成的交易
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // 检查是否是 Pro 产品
                if transaction.productID == proProductID {
                    hasPurchased = true
                    break
                }
            } catch {
                print("❌ StoreKit: 验证交易失败 - \(error)")
            }
        }
        
        if hasPurchased {
            await ProEntitlementManager.shared.markPurchased()
        }
    }
    
    // MARK: - Verification
    
    /// 验证交易
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "PurchaseManager", code: -2, userInfo: [NSLocalizedDescriptionKey: AppText.PurchaseError.verificationFailed])
        case .verified(let safe):
            return safe
        }
    }
}

