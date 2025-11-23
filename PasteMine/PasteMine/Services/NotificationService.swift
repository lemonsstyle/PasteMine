//
//  NotificationService.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import UserNotifications
import Foundation

class NotificationService {
    static let shared = NotificationService()
    
    private init() {
        requestPermission()
    }
    
    /// 请求通知权限
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("✅ 通知权限已授予")
            } else {
                print("⚠️  通知权限被拒绝")
            }
        }
    }
    
    /// 发送剪贴板更新通知
    func sendClipboardNotification(content: String) {
        let settings = AppSettings.load()
        guard settings.notificationEnabled else {
            print("📢 通知已禁用")
            return
        }
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "剪贴板已更新"
        
        // 截断内容，最多显示 50 个字符
        let truncated = content.count > 50 
            ? String(content.prefix(50)) + "..."
            : content
        notificationContent.body = truncated
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notificationContent,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 发送通知失败: \(error)")
            } else {
                print("✅ 通知已发送")
            }
        }
    }
}

