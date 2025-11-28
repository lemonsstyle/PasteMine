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
    func sendClipboardNotification(content: String, isImage: Bool = false) {
        let settings = AppSettings.load()
        guard settings.notificationEnabled else {
            print("📢 通知已在应用设置中禁用")
            return
        }

        // 检查系统通知权限
        UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
            print("📊 系统通知权限状态: \(notificationSettings.authorizationStatus.rawValue)")
            print("📊 通知样式: \(notificationSettings.alertStyle.rawValue)")
            print("📊 是否允许声音: \(notificationSettings.soundSetting.rawValue)")

            guard notificationSettings.authorizationStatus == .authorized else {
                print("⚠️ 系统通知权限未授予，无法发送通知")
                print("请在 系统设置 > 通知 > PasteMine 中开启通知")
                return
            }

            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = isImage ? "📸 复制了图片" : "📋 剪贴板已更新"

            // 截断内容，最多显示 50 个字符
            let truncated = content.count > 50
                ? String(content.prefix(50)) + "..."
                : content
            notificationContent.body = truncated
            notificationContent.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: notificationContent,
                trigger: nil
            )

            print("📤 准备发送通知: \(truncated)")

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ 发送通知失败: \(error.localizedDescription)")
                } else {
                    print("✅ 通知已成功添加到通知中心: \(truncated)")
                }
            }

            // 播放复制音效
            SoundService.shared.playCopySound()
        }
    }

    /// 发送粘贴通知
    func sendPasteNotification(content: String, isImage: Bool = false) {
        let settings = AppSettings.load()
        guard settings.notificationEnabled else {
            print("📢 通知已在应用设置中禁用")
            return
        }

        // 检查系统通知权限
        UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
            guard notificationSettings.authorizationStatus == .authorized else {
                print("⚠️ 系统通知权限未授予，无法发送粘贴通知")
                return
            }

            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = isImage ? "📸 已粘贴图片" : "📋 已粘贴文本"

            // 截断内容，最多显示 50 个字符
            let truncated = content.count > 50
                ? String(content.prefix(50)) + "..."
                : content
            notificationContent.body = truncated
            notificationContent.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: notificationContent,
                trigger: nil
            )

            print("📤 准备发送粘贴通知: \(truncated)")

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ 发送粘贴通知失败: \(error.localizedDescription)")
                } else {
                    print("✅ 粘贴通知已成功添加到通知中心: \(truncated)")
                }
            }

            // 播放粘贴音效
            SoundService.shared.playPasteSound()
        }
    }
}

