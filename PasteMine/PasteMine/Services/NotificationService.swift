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
        // 先检查当前权限状态
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📊 当前通知权限状态: \(settings.authorizationStatus.rawValue)")
            print("   - 0: notDetermined (未请求)")
            print("   - 1: denied (已拒绝)")
            print("   - 2: authorized (已授权)")

            // 如果还未请求过权限，则请求
            if settings.authorizationStatus == .notDetermined {
                print("🔔 首次启动，正在请求通知权限...")

                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("❌ 请求通知权限时出错: \(error.localizedDescription)")
                        return
                    }

                    if granted {
                        print("✅ 通知权限已授予")
                        // 再次检查详细设置
                        UNUserNotificationCenter.current().getNotificationSettings { newSettings in
                            print("📊 通知详细设置:")
                            print("   授权状态: \(newSettings.authorizationStatus.rawValue)")
                            print("   警报样式: \(newSettings.alertSetting.rawValue)")
                            print("   声音设置: \(newSettings.soundSetting.rawValue)")
                        }
                    } else {
                        print("⚠️  通知权限被拒绝")
                        print("   请在系统设置中手动开启: 系统设置 > 通知 > PasteMine")
                    }
                }
            } else if settings.authorizationStatus == .denied {
                print("⚠️  通知权限已被拒绝")
                print("   请在系统设置中手动开启: 系统设置 > 通知 > PasteMine")
            } else if settings.authorizationStatus == .authorized {
                print("✅ 通知权限已授权")
            }
        }
    }
    
    /// 发送剪贴板更新通知
    func sendClipboardNotification(content: String, isImage: Bool = false) {
        let settings = AppSettings.load()
        guard settings.notificationEnabled else {
            print("📢 通知已禁用（应用设置）")
            return
        }

        // 检查系统通知授权状态
        UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
            print("📊 通知授权状态: \(notificationSettings.authorizationStatus.rawValue)")
            print("   - 0: notDetermined, 1: denied, 2: authorized, 3: provisional, 4: ephemeral")
            print("📊 警报样式: \(notificationSettings.alertSetting.rawValue)")
            print("   - 0: notSupported, 1: disabled, 2: enabled")
            print("📊 声音设置: \(notificationSettings.soundSetting.rawValue)")

            guard notificationSettings.authorizationStatus == .authorized else {
                print("❌ 通知未授权，请在系统设置中允许通知")
                print("   路径: 系统设置 > 通知 > PasteMine")
                return
            }

            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = isImage ? "📸 复制了图片" : "📋 剪贴板已更新"

            // 截断内容，最多显示 50 个字符
            let truncated = content.count > 50
                ? String(content.prefix(50)) + "..."
                : content
            notificationContent.body = truncated
            // 不使用系统通知声音，使用自定义音效（避免双重声音）
            notificationContent.sound = nil

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: notificationContent,
                trigger: nil
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ 发送通知失败: \(error.localizedDescription)")
                } else {
                    print("✅ 通知已成功发送: \(truncated)")
                }
            }
        }

        // 播放复制音效
        SoundService.shared.playCopySound()
    }

    /// 发送粘贴通知
    func sendPasteNotification(content: String, isImage: Bool = false) {
        let settings = AppSettings.load()
        guard settings.notificationEnabled else {
            print("📢 通知已禁用（应用设置）")
            return
        }

        // 检查系统通知授权状态
        UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
            print("📊 粘贴通知授权状态: \(notificationSettings.authorizationStatus.rawValue)")

            guard notificationSettings.authorizationStatus == .authorized else {
                print("❌ 通知未授权，请在系统设置中允许通知")
                return
            }

            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = isImage ? "📸 已粘贴图片" : "📋 已粘贴文本"

            // 截断内容，最多显示 50 个字符
            let truncated = content.count > 50
                ? String(content.prefix(50)) + "..."
                : content
            notificationContent.body = truncated
            // 不使用系统通知声音，使用自定义音效（避免双重声音）
            notificationContent.sound = nil

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: notificationContent,
                trigger: nil
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ 发送粘贴通知失败: \(error.localizedDescription)")
                } else {
                    print("✅ 粘贴通知已成功发送: \(truncated)")
                }
            }
        }

        // 播放粘贴音效
        SoundService.shared.playPasteSound()
    }
}

