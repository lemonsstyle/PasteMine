//
//  Settings.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import Foundation

struct AppSettings: Codable {
    var notificationEnabled: Bool = true
    var soundTheme: Int = 1  // 音效主题：1/2/3
    var globalShortcut: KeyboardShortcut = .defaultShortcut  // 默认 ⌘⇧V
    var maxHistoryCount: Int = 50  // 默认 50 条
    var retentionDays: Int = 3      // 默认 3 天（0 = 永久）
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
    static let historyCountOptions = [50, 100, 200]
    
    /// 保留天数选项（0 表示永久）
    static let retentionDaysOptions = [
        (value: 3, label: "3 天"),
        (value: 7, label: "7 天"),
        (value: 0, label: "永久")
    ]
    
    /// 图片大小限制选项（MB）
    static let imageSizeOptions = [5, 10, 20]

    /// 音效主题选项
    static let soundThemeOptions = [
        (value: 1, label: "音效 1"),
        (value: 2, label: "音效 2"),
        (value: 3, label: "音效 3")
    ]
}

