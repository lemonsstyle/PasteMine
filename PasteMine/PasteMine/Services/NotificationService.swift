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
    
    // 缓存权限状态，避免每次异步检查
    private var isAuthorized: Bool = false
    
    // 节流控制：防止短时间内发送过多通知被系统抑制
    private var lastCopyNotificationTime: Date = .distantPast
    private var lastPasteNotificationTime: Date = .distantPast
    private let minNotificationInterval: TimeInterval = 0.3  // 最小间隔 0.3 秒
    private var lastPermissionWarningTime: Date = .distantPast
    private let minPermissionWarningInterval: TimeInterval = 2.0
    
    private init() {
        // 不在 init 中自动请求权限
        // 权限请求应该在引导界面或应用完全初始化后进行
        // 这样可以确保应用处于激活状态，系统弹窗能正常显示
    }
    
    /// 请求通知权限
    func requestPermission() {
        // 先检查当前权限状态
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            print("📊 当前通知权限状态: \(settings.authorizationStatus.rawValue)")
            print("   - 0: notDetermined (未请求)")
            print("   - 1: denied (已拒绝)")
            print("   - 2: authorized (已授权)")
            
            // 更新缓存的权限状态
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }

            // 如果还未请求过权限，则请求
            if settings.authorizationStatus == .notDetermined {
                print("🔔 首次启动，正在请求通知权限...")

                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
                    if let error = error {
                        print("❌ 请求通知权限时出错: \(error.localizedDescription)")
                        return
                    }

                    // 更新缓存的权限状态
                    DispatchQueue.main.async {
                        self?.isAuthorized = granted
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
    
    /// 刷新权限状态缓存
    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
                print("🔄 权限状态已刷新: \(settings.authorizationStatus == .authorized ? "已授权" : "未授权")")
            }
        }
    }
    
    /// 发送剪贴板更新通知
    func sendClipboardNotification(content: String, isImage: Bool = false) {
        let settings = AppSettings.load()
        guard settings.notificationEnabled else {
            print("📢 通知已禁用（应用设置）")
            // 即使通知禁用，也播放音效
            SoundService.shared.playCopySound()
            return
        }

        // 节流检查：防止短时间内发送过多通知
        let now = Date()
        if now.timeIntervalSince(lastCopyNotificationTime) < minNotificationInterval {
            print("⏳ 通知节流：距离上次通知时间过短，跳过本次通知")
            // 即使跳过通知，也播放音效
            SoundService.shared.playCopySound()
            return
        }
        lastCopyNotificationTime = now

        // 使用缓存的权限状态，避免异步检查带来的不确定性
        guard isAuthorized else {
            print("❌ 通知未授权（缓存状态），尝试刷新权限状态")
            print("   路径: 系统设置 > 通知 > PasteMine")
            // 刷新权限状态以备下次使用
            refreshAuthorizationStatus()
            // 即使通知未授权，也播放音效
            SoundService.shared.playCopySound()
            return
        }

        // 构建通知内容
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = isImage ? AppText.Notifications.copyImageTitle : AppText.Notifications.copyTitle

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

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            // 确保在主线程执行后续操作
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 发送通知失败: \(error.localizedDescription)")
                    // 发送失败时刷新权限状态
                    self?.refreshAuthorizationStatus()
                } else {
                    print("✅ 通知已成功发送: \(truncated)")
                }
                // 无论通知发送成功与否，都播放音效
                SoundService.shared.playCopySound()
            }
        }
    }

    /// 发送剪贴板未更新通知（如大图被忽略）
    func sendClipboardSkippedNotification(reason: String) {
        let settings = AppSettings.load()
        guard settings.notificationEnabled else {
            print("📢 通知已禁用（应用设置）")
            return
        }

        guard isAuthorized else {
            refreshAuthorizationStatus()
            return
        }

        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = AppText.Notifications.skippedTitle
        notificationContent.body = reason
        notificationContent.sound = nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notificationContent,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 发送未更新通知失败: \(error.localizedDescription)")
            } else {
                print("ℹ️ 已发送未更新通知: \(reason)")
            }
        }
    }

    /// 发送粘贴通知
    func sendPasteNotification(content: String, isImage: Bool = false) {
        let settings = AppSettings.load()
        guard settings.notificationEnabled else {
            print("📢 通知已禁用（应用设置）")
            // 即使通知禁用，也播放音效
            SoundService.shared.playPasteSound()
            return
        }

        // 节流检查：防止短时间内发送过多通知
        let now = Date()
        if now.timeIntervalSince(lastPasteNotificationTime) < minNotificationInterval {
            print("⏳ 通知节流：距离上次通知时间过短，跳过本次通知")
            // 即使跳过通知，也播放音效
            SoundService.shared.playPasteSound()
            return
        }
        lastPasteNotificationTime = now

        // 使用缓存的权限状态，避免异步检查带来的不确定性
        guard isAuthorized else {
            print("❌ 粘贴通知未授权（缓存状态），尝试刷新权限状态")
            // 刷新权限状态以备下次使用
            refreshAuthorizationStatus()
            // 即使通知未授权，也播放音效
            SoundService.shared.playPasteSound()
            return
        }

        // 构建通知内容
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = isImage ? AppText.Notifications.pasteImageTitle : AppText.Notifications.pasteTextTitle

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

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            // 确保在主线程执行后续操作
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 发送粘贴通知失败: \(error.localizedDescription)")
                    // 发送失败时刷新权限状态
                    self?.refreshAuthorizationStatus()
                } else {
                    print("✅ 粘贴通知已成功发送: \(truncated)")
                }
                // 无论通知发送成功与否，都播放音效
                SoundService.shared.playPasteSound()
            }
        }
    }
    
    /// 辅助功能权限缺失时的提醒
    func sendAccessibilityPermissionWarning() {
        let now = Date()
        guard now.timeIntervalSince(lastPermissionWarningTime) >= minPermissionWarningInterval else {
            return
        }
        lastPermissionWarningTime = now
        
        let settings = AppSettings.load()
        guard settings.notificationEnabled else {
            print("⚠️ 辅助功能权限缺失，通知已关闭，无法提示用户")
            return
        }
        
        guard isAuthorized else {
            print("⚠️ 辅助功能权限缺失，同时通知权限未授权，提示失败")
            refreshAuthorizationStatus()
            return
        }
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = AppText.Notifications.accessibilityMissingTitle
        notificationContent.body = AppText.Notifications.accessibilityMissingBody
        notificationContent.sound = nil
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notificationContent,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 发送辅助功能提示通知失败: \(error.localizedDescription)")
            } else {
                print("⚠️ 已提醒用户授予辅助功能权限")
            }
        }
    }
}
