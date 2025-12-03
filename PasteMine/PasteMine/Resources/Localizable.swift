//
//  Localizable.swift
//  PasteMine
//
//  统一管理应用内所有显示文字
//  便于后续字体、字号调整和多语言翻译
//

import Foundation

/// 应用内所有文字的统一管理
enum AppText {
    
    // MARK: - 设置页面
    enum Settings {
        static let title = "设置"
        static let doneButton = "完成"
        
        // 分组标题
        enum Groups {
            static let general = "通用"
            static let storage = "存储"
            static let privacy = "隐私"
        }
        
        // 通用设置
        enum General {
            static let notification = "通知"
            static let notificationDesc = "复制时显示通知"
            
            static let sound = "音效"
            static let soundDesc = "播放提示音效"
            
            static let globalShortcut = "全局快捷键"
            static let globalShortcutDesc = "显示/隐藏窗口"
            
            static let launchAtLogin = "开机自启动"
            static let launchAtLoginDesc = "自动启动应用"
        }
        
        // 存储设置
        enum Storage {
            static let historyLimit = "历史记录上限"
            static let historyLimitDesc = "超出自动删除"
            static let historyPermanent = "永久"
            static func historyCount(_ count: Int) -> String { "\(count) 条" }
            
            static let ignoreLargeImages = "忽略大图片以节省磁盘空间"
            static let ignoreLargeImagesDesc = "超过 20MB 的图片将不会被保存到历史中"
        }
        
        // 隐私设置
        enum Privacy {
            static let ignoreApps = "忽略应用"
            static let ignoreTypes = "忽略类型"
            
            static let selectApp = "选择应用"
            static let ignoreAppsDesc = "这些应用中的复制操作不会被记录"
            
            static let addType = "添加"
            static let typeListTitle = "类型列表"
            static let typePlaceholder = "输入 pasteboard type"
            static let ignoreTypesDesc = "这些类型的隐私内容不会被记录"
            static let ignoreTypesToggleLabel = "启用忽略类型"
            
            static let clearOnQuit = "退出时清空剪贴板"
            static let clearOnQuitDesc = "退出应用时自动清除所有历史记录"
            
            static let emptyList = "列表为空"
        }
    }
    
    // MARK: - 主窗口
    enum MainWindow {
        static let windowTitle = "剪贴板历史"
        static let searchPlaceholder = "搜索..."
        static let emptyStateTitle = "暂无剪贴板记录"
        static let emptyStateMessage = "开始复制内容，它们会出现在这里"
        static let clearAll = "清空"
        static let settings = "设置"
        
        // 筛选相关
        static let filterAll = "全部"
        static let filterMore = "..."
    }
    
    // MARK: - 引导页面
    enum Onboarding {
        static let title = "欢迎使用 PasteMine"
        static let step1Title = "📋 自动记录"
        static let step1Desc = "自动记录你的复制内容\n支持文本和图片"
        
        static let step2Title = "⌨️ 快捷访问"
        static let step2Desc = "使用快捷键快速调出历史\n默认：⌘⇧V"
        
        static let step3Title = "🔒 隐私保护"
        static let step3Desc = "可设置忽略特定应用\n保护敏感信息"
        
        static let getStarted = "开始使用"
        static let permissionTitle = "需要授予权限"
        static let permissionMessage = "为了正常工作，请在系统设置中授予通知权限"
    }
    
    // MARK: - 通知
    enum Notifications {
        static let copyTitle = "📋 剪贴板已更新"
        static let copyImageTitle = "📸 复制了图片"
        static let pasteTitle = "📋 粘贴成功"
    }
    
    // MARK: - 右键菜单
    enum Menu {
        static let showWindow = "显示窗口"
        static let quit = "退出"
    }
    
    // MARK: - 通用
    enum Common {
        static let delete = "删除"
        static let cancel = "取消"
        static let confirm = "确认"
        static let copy = "复制"
        static let paste = "粘贴"
    }
}
