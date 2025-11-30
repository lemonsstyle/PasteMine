//
//  Settings.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import Foundation

struct AppSettings: Codable {
    var notificationEnabled: Bool = true
    var soundEnabled: Bool = true  // 音效开关
    var launchAtLogin: Bool = false  // 开机自启动
    var globalShortcut: KeyboardShortcut = .defaultShortcut  // 默认 ⌘⇧V
    var maxHistoryCount: Int = 50  // 默认 50 条
    var maxImageSize: Int = 10      // 默认 10MB
    
    // 存储到 UserDefaults
    static let key = "app_settings"
    
    /// 从 UserDefaults 加载设置
    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
    
    /// 保存设置到 UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
        
        // 通知快捷键已更改
        NotificationCenter.default.post(name: .shortcutDidChange, object: nil)
    }
    
    /// 历史记录数量选项
    static let historyCountOptions = [50, 200, 999]

    /// 图片大小限制选项（MB）
    static let imageSizeOptions = [5, 10, 20]
}

