//
//  Settings.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import Foundation

struct AppSettings: Codable {
    var notificationEnabled: Bool = true
    var globalShortcut: String = "⌘⇧V"
    var maxHistoryCount: Int = 100
    
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
    }
}

