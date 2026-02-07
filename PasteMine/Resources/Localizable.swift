//
//  Localizable.swift
//  PasteMine
//
//  统一管理应用内所有显示文字
//  便于后续字体、字号调整和多语言翻译
//

import Foundation

enum AppLanguage {
    case zhHans
    case en

    static var current: AppLanguage {
        if let code = Locale.preferredLanguages.first?.lowercased(),
           code.hasPrefix("zh") {
            return .zhHans
        }
        return .en
    }
}

enum L10n {
    static func text(_ zh: String, _ en: String) -> String {
        AppLanguage.current == .zhHans ? zh : en
    }
}

enum AppText {
    private static let lang = AppLanguage.current
    private static func t(_ zh: String, _ en: String) -> String { lang == .zhHans ? zh : en }
    
    // MARK: - 设置页面
    enum Settings {
        static var title: String { t("设置", "Settings") }
        static var doneButton: String { t("完成", "Done") }
        static var groupGeneral: String { t("通用", "General") }
        static var groupStorage: String { t("存储", "Storage") }
        static var groupPrivacy: String { t("隐私", "Privacy") }
        
        // 分组标题
        enum Groups {
            static var general: String { t("通用", "General") }
            static var storage: String { t("存储", "Storage") }
            static var privacy: String { t("隐私", "Privacy") }
        }
        
        // 通用设置
        enum General {
            static var clipboardHistory: String { t("启用剪贴板历史记录", "Enable clipboard history") }
            static var clipboardHistoryDesc: String { t("开启后才会在本机保存最近的剪贴板内容，可随时关闭", "Only after enabling will recent clipboard content be saved locally; you can turn it off anytime.") }
            static var notification: String { t("通知", "Notifications") }
            static var notificationDesc: String { t("复制时显示通知", "Show notification when copying") }
            
            static var sound: String { t("音效", "Sound") }
            static var soundDesc: String { t("播放提示音效", "Play sound on actions") }
            
            static var globalShortcut: String { t("全局快捷键", "Global shortcut") }
            static var globalShortcutDesc: String { t("显示/隐藏窗口", "Show / hide window") }
            
            static var launchAtLogin: String { t("开机自启动", "Launch at login") }
            static var launchAtLoginDesc: String { t("自动启动应用", "Start automatically on login") }
            static var launchAtLoginUnsupported: String { t("该功能仅支持 macOS 13 及以上系统", "Available on macOS 13+") }
        }
        
        // 存储设置
        enum Storage {
            static var historyLimit: String { t("历史记录上限", "History limit") }
            static var historyLimitDesc: String { t("超出自动删除", "Auto-delete when exceeding limit") }
            static var historyPermanent: String { t("永久", "Unlimited") }
            static func historyCount(_ count: Int) -> String { t("\(count) 条", "\(count) items") }
            
            static var ignoreLargeImages: String { t("忽略大图片以节省磁盘空间", "Ignore large images to save disk space") }
            static var ignoreLargeImagesDesc: String { t("超过 20MB 的图片将不会被保存到历史中", "Images over 20MB will not be saved") }
            
            static var imagePreview: String { t("图片悬停预览", "Image hover preview") }
            static var imagePreviewDesc: String { t("悬停 0.7 秒显示放大预览（默认关闭）", "Show enlarged preview after 0.7s hover (off by default)") }
        }
        
        // 隐私设置
        enum Privacy {
            static var ignoreApps: String { t("忽略应用", "Ignored apps") }
            static var ignoreTypes: String { t("忽略类型", "Ignored types") }
            
            static var selectApp: String { t("选择应用", "Select app") }
            static var ignoreAppsDesc: String { t("这些应用中的复制操作不会被记录", "Copies from these apps will be ignored") }
            static var defaultIgnoredAppsDesc: String { t("PasteMine 默认已忽略常见密码管理器和自动填充工具，您可在此增删。", "Common password managers and autofill tools are ignored by default; adjust as needed.") }
            
            static var addType: String { t("添加", "Add") }
            static var typeListTitle: String { t("类型列表", "Type list") }
            static var typePlaceholder: String { t("输入 pasteboard type", "Enter pasteboard type") }
            static var ignoreTypesDesc: String { t("这些类型的隐私内容不会被记录", "These sensitive types will not be recorded") }
            static var defaultIgnoredTypesDesc: String { t("已预置密码字段等敏感剪贴板类型，可根据需要调整。", "Sensitive pasteboard types (password/OTP) are preset; adjust as needed.") }
            static var ignoreTypesToggleLabel: String { t("启用忽略类型", "Enable ignored types") }
            
            static var clearOnQuit: String { t("退出时清空剪贴板", "Clear history on quit") }
            static var clearOnQuitDesc: String { t("退出应用时自动清除所有历史记录", "Automatically remove all history when quitting") }
            
            static var emptyList: String { t("列表为空", "Empty list") }
        }
    }
    
    // MARK: - 主窗口
    enum MainWindow {
        static var windowTitle: String { "PasteMine" }
        static var searchPlaceholder: String { t("搜索...", "Search...") }
        static var emptyStateTitle: String { t("暂无剪贴板记录", "No clipboard items yet") }
        static var emptyStateMessage: String { t("开始复制内容，它们会出现在这里", "Start copying and items will show here") }
        static var clearAll: String { t("清空", "Clear all") }
        static var settings: String { t("设置", "Settings") }
        
        // 筛选相关
        static var filterAll: String { t("全部", "All") }
        static var filterMore: String { "..." }
    }

    // MARK: - 通知
    enum Notifications {
        static var copyTitle: String { t("📋 剪贴板已更新", "📋 Clipboard updated") }
        static var copyImageTitle: String { t("📸 复制了图片", "📸 Image copied") }
        static var pasteTextTitle: String { t("📋 已粘贴文本", "📋 Text pasted") }
        static var pasteImageTitle: String { t("📸 已粘贴图片", "📸 Image pasted") }
        static var skippedTitle: String { t("已忽略一张大图片", "Large image skipped") }
        static var skippedLargeImage: String { t("图片大于 20MB，PasteMine 未将其加入历史。", "Image exceeds 20MB. PasteMine didn't add it to history.") }
        static var accessibilityMissingTitle: String { t("需要辅助功能权限", "Accessibility permission required") }
        static var accessibilityMissingBody: String { t("未授予辅助功能权限，PasteMine 只能复制内容。请前往 系统设置 > 隐私与安全 > 辅助功能 中开启。", "Accessibility not granted. PasteMine can only copy. Go to System Settings > Privacy & Security > Accessibility to enable.") }
    }
    
    // MARK: - 右键菜单
    enum Menu {
        static var showWindow: String { t("显示窗口", "Show Window") }
        static var quit: String { t("退出", "Quit") }
        static var clipboardHistory: String { t("剪贴板历史", "Clipboard History") }
    }
    
    // MARK: - 通用
    enum Common {
        static var delete: String { t("删除", "Delete") }
        static var cancel: String { t("取消", "Cancel") }
        static var confirm: String { t("确认", "Confirm") }
        static var copy: String { t("复制", "Copy") }
        static var paste: String { t("粘贴", "Paste") }
        static var imageLabel: String { t("图片", "Image") }
        static var pinned: String { t("固定", "Pin") }
        static var unpinned: String { t("取消固定", "Unpin") }
        static var noMatches: String { t("没有找到匹配的记录", "No matching records") }
        static var ok: String { t("确定", "OK") }
        static var close: String { t("关闭", "Close") }

        // 快捷键录制
        static var recordShortcut: String { t("录制", "Record") }
        static var finishRecording: String { t("完成", "Done") }
        static var resetShortcut: String { t("重置", "Reset") }
        static var pressShortcut: String { t("按下快捷键...", "Press shortcut...") }
    }
    
    // MARK: - Pro 功能
    enum Pro {
        // Pro 按钮
        static var proButton: String { t("PRO", "PRO") }
        static var upgradeTooltip: String { t("升级到 PasteMine Pro", "Upgrade to PasteMine Pro") }
        
        // Pro 面板标题
        static var sheetTitle: String { t("升级到 PasteMine Pro", "Upgrade to PasteMine Pro") }
        static var sheetSubtitle: String { t("更长的历史、更强的预览、更顺手的整理。", "Longer history, better preview, smarter organization.") }
        static var upgradeExperience: String { t("全面升级你的剪贴板体验", "Enhance your clipboard experience") }
        
        // 特性卡片
        enum Features {
            static var longerHistoryTitle: String { t("更长历史", "Longer History") }
            static var longerHistoryDesc: String { t("免费版仅保留最近 50 条，Pro 可选择 200 条或几乎无限（999 条）。", "Free: 50 items. Pro: up to 200 or 999 items.") }
            
            static var hoverPreviewTitle: String { t("悬停预览", "Hover Preview") }
            static var hoverPreviewDesc: String { t("将鼠标停在图片记录上，无需打开即可查看原图细节。", "Hover over images to preview full details without opening.") }
            
            static var sourceTagsTitle: String { t("来源分类", "Source Tags") }
            static var sourceTagsDesc: String { t("为复制内容添加 浏览器 / 微信 / 备忘录等分类，查找复制更有条理。", "Categorize content by Browser / WeChat / Notes for more organized search.") }
            
            static var unlimitedPinsTitle: String { t("无限固定", "Unlimited Pins") }
            static var unlimitedPinsDesc: String { t("免费版最多固定 2 条，Pro 可固定任意数量的重要记录。", "Free: 2 pins. Pro: unlimited important items.") }
        }
        
        // 按钮文案
        static var purchaseButton: String { t("立即升级到 Pro", "Upgrade to Pro Now") }
        static var purchaseButtonTrial: String { t("现在买断，体验不中断", "Buy Now, Keep the Experience") }
        static var purchaseButtonExpired: String { t("解锁 PasteMine Pro", "Unlock PasteMine Pro") }
        static var alreadyPurchased: String { t("已解锁 PasteMine Pro", "PasteMine Pro Unlocked") }
        
        static var oneTimePurchase: String { t("一次性买断 · 未来版本持续使用", "One-time purchase · Lifetime updates") }
        static var restorePurchase: String { t("恢复购买", "Restore Purchase") }
        static var sendFeedback: String { t("给开发者反馈…", "Send Feedback…") }
        static var continueFreePlan: String { t("继续使用免费版", "Continue with Free") }
        
        // 免费试用
        static var freeTrialButton: String { t("免费体验 7 天", "Free 7-Day Trial") }
        static var or: String { t("或", "or") }
        
        // 上下文横幅
        static func trialActiveBanner(daysLeft: Int) -> String {
            t("免费体验 PasteMine Pro（还剩 \(daysLeft) 天）。到期自动恢复为免费版，无自动扣费。",
              "Free trial active (\(daysLeft) days left). Will revert to Free plan. No auto-charge.")
        }
        
        static var trialExpiredBanner: String {
            t("PasteMine Pro 免费体验已结束，当前已回到免费版。如需继续使用 Pro 功能，请解锁 PasteMine Pro。",
              "Free trial ended. Now on Free plan. Unlock Pro to continue using Pro features.")
        }
        
        static var purchasedBanner: String {
            t("你已经解锁 PasteMine Pro，感谢支持！",
              "PasteMine Pro unlocked. Thank you for your support!")
        }
        
        // 购买结果提示
        static var purchaseSuccess: String { t("购买成功！感谢支持 PasteMine Pro！", "Purchase successful! Thank you for supporting PasteMine Pro!") }
        static var restoreSuccess: String { t("恢复购买成功！", "Purchase restored successfully!") }
        static func purchaseFailed(error: String) -> String {
            t("购买失败：\(error)", "Purchase failed: \(error)")
        }
        static var alertTitle: String { t("提示", "Notice") }
        
        // 设置页相关
        static var freeVersionBadge: String { t("免费版: 50 条", "Free: 50 items") }
        static var upgradeForMoreHistory: String { t("升级到 Pro 解锁 200/无限条，免费版仅 50 条", "Upgrade to Pro for 200/unlimited items, free version limited to 50") }
        static var proLabel: String { t("Pro", "Pro") }
        static var upgradeForImagePreview: String { t("升级到 Pro 解锁图片悬停预览功能", "Upgrade to Pro to unlock image hover preview") }
        
        // 固定限制
        static var unlimitedPinsTitle: String { t("升级到 Pro 解锁无限固定", "Upgrade to Pro for Unlimited Pins") }
        static var unlimitedPinsMessage: String {
            t("免费版最多固定 2 条记录，Pro 用户可以固定任意数量的重要内容。",
              "Free plan: 2 pins. Pro: unlimited pins for important items.")
        }
        static var upgradeToPro: String { t("升级到 Pro", "Upgrade to Pro") }
        
        // 清空历史确认
        static var clearAllTitle: String { t("确定要清空所有历史记录吗？", "Clear all history?") }
        static var clearAllMessage: String { t("此操作不可撤销", "This action cannot be undone.") }
    }

    // MARK: - 引导页面
    enum Onboarding {
        static var title: String { t("欢迎使用 PasteMine", "Welcome to PasteMine") }

        // 欢迎页面
        static var welcomeTitle: String { t("PasteMine", "PasteMine") }
        static var welcomeSlogan: String {
            t("从此告别「复制过什么」的烦恼", "Never lose what you copied")
        }

        // 功能卡片
        static var feature1Title: String {
            t("📋 自动保存所有复制", "📋 Auto-save all copies")
        }
        static var feature1Desc: String {
            t("文本、图片、链接...永远不会丢失", "Text, images, links... never lost")
        }

        static var feature2Title: String {
            t("⚡️ 一秒唤出历史", "⚡️ Instant access")
        }
        static var feature2Desc: String {
            t("⌘⇧V 快捷键或点击菜单栏图标", "⌘⇧V shortcut or menu bar icon")
        }

        static var feature3Title: String {
            t("🎯 智能搜索与筛选", "🎯 Smart search & filter")
        }
        static var feature3Desc: String {
            t("按应用分类、关键词搜索，快速找到内容",
              "Filter by app, search by keyword, find instantly")
        }

        static var startSetup: String { t("开始设置", "Start setup") }

        // 通知权限页面
        static var enableNotifications: String { t("开启通知", "Enable notifications") }
        static var notificationDesc: String { t("接收剪贴板复制和粘贴提醒", "Get alerts for copy and paste") }
        static var notificationBenefitsTitle: String {
            t("通知将帮助您：", "Notifications help you:")
        }
        static var benefit1: String {
            t("确认成功复制长文本或大图片", "Confirm long text or large image copied")
        }
        static var benefit2: String {
            t("自动粘贴完成后的即时反馈", "Instant feedback after auto-paste")
        }
        static var benefit3: String {
            t("历史记录达到上限时提醒", "Alert when history limit reached")
        }
        static var benefit4: String {
            t("检测到敏感内容时的隐私提示", "Privacy alert for sensitive content")
        }
        static var nonIntrusive: String {
            t("所有通知均为轻量级，不会打断您的工作", "All notifications are lightweight and non-intrusive")
        }

        // 辅助功能页面
        static var enableAccessibility: String { t("开启辅助功能", "Enable Accessibility") }
        static var unlockCoreFeatures: String {
            t("解锁 PasteMine 的核心能力", "Unlock PasteMine's core features")
        }
        static var withoutPermission: String { t("无权限", "Without") }
        static var withPermission: String { t("有权限", "With") }
        static var withoutDesc: String { t("只能查看\n手动复制", "View only\nManual copy") }
        static var withDesc: String {
            t("一键粘贴\n全局快捷键", "One-click paste\nGlobal shortcut")
        }
        static var setupSteps: String { t("设置步骤：", "Setup:") }
        static var step1Simple: String {
            t("点击按钮打开「系统设置」", "Open System Settings")
        }
        static var step2Simple: String {
            t("找到「辅助功能」并勾选 PasteMine", "Find Accessibility and check PasteMine")
        }
        static var step3Simple: String {
            t("输入密码确认（可能需要）", "Enter password if prompted")
        }
        static var securityPromise: String {
            t("PasteMine 仅用于粘贴操作，不会访问其他应用数据",
              "PasteMine only uses this for paste, no data access")
        }

        // 完成页面
        static var setupComplete: String { t("设置完成！", "Setup Complete!") }
        static var nowReady: String {
            t("现在可以开始使用 PasteMine 了", "You're ready to use PasteMine")
        }
        static var shortcutLabel: String { t("快捷键", "Shortcut") }
        static var shortcutDesc: String {
            t("随时唤出剪贴板历史", "Open clipboard history anytime")
        }
        static var quickStartLabel: String { t("快速上手", "Quick start") }
        static var quickTip1: String {
            t("复制任何内容，PasteMine 自动记录", "Copy anything, PasteMine auto-saves")
        }
        static var quickTip2: String {
            t("点击历史记录即可自动粘贴", "Click history item to auto-paste")
        }
        static var quickTip3: String {
            t("搜索框支持关键词和应用筛选", "Search by keyword or filter by app")
        }
        static var tryNow: String { t("立即体验", "Try it now") }
        static var startLater: String { t("稍后开始", "Start later") }
        static var grantPermission: String { t("授予权限", "Grant permission") }
        static var maybeLater: String { t("稍后设置", "Maybe later") }
        static var nextStep: String { t("下一步", "Next") }
        static var permissionDenied: String { t("权限已被拒绝", "Permission denied") }
        static var enableInSettings: String { t("请在系统设置中手动开启", "Please enable it in System Settings") }
        static var missingPermissions: String {
            t("您可以稍后在系统设置中开启缺失的权限",
              "You can enable missing permissions later in System Settings")
        }
        static var notificationLabel: String { t("通知权限", "Notification") }
        static var accessibilityLabel: String { t("辅助功能权限", "Accessibility") }
    }

    // MARK: - 辅助功能权限
    enum Accessibility {
        static var permissionRequired: String { t("需要辅助功能权限", "Accessibility Permission Required") }
        static var permissionMessage: String {
            t("PasteMine 需要辅助功能权限来实现：\n• 自动粘贴功能\n• 全局快捷键 (⌘⇧V)\n\n请在系统偏好设置中授予权限。",
              "PasteMine needs accessibility permission for:\n• Auto-paste functionality\n• Global shortcut (⌘⇧V)\n\nPlease grant permission in System Preferences.")
        }
        static var openSystemPreferences: String { t("打开系统偏好设置", "Open System Preferences") }
        static var later: String { t("稍后", "Later") }
    }

    // MARK: - 应用选择器
    enum AppPicker {
        static var selectAppTitle: String { t("选择要忽略的应用", "Select App to Ignore") }
        static var selectAppMessage: String { t("请选择一个应用程序", "Please select an application") }
    }

    // MARK: - 权限状态
    enum PermissionStatus {
        static var granted: String { t("已授权", "Granted") }
        static var notGranted: String { t("未授权", "Not Granted") }
    }

    // MARK: - 购买错误
    enum PurchaseError {
        static var productNotLoaded: String { t("产品未加载", "Product Not Loaded") }
        static var verificationFailed: String { t("交易验证失败", "Transaction Verification Failed") }
    }
}
