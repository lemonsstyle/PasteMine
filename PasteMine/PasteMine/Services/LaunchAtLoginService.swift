//
//  LaunchAtLoginService.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/28.
//

import Foundation
import ServiceManagement

/// 开机自启动服务
class LaunchAtLoginService {
    static let shared = LaunchAtLoginService()

    private init() {}

    /// 设置开机自启动状态
    func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            // macOS 13+ 使用新的 ServiceManagement API
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    print("✅ 开机自启动已启用")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("❌ 开机自启动已禁用")
                }
            } catch {
                print("⚠️ 设置开机自启动失败: \(error)")
            }
        } else {
            // macOS 13 以下使用旧的 API
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.lemonstyle.PasteMine"
            let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled)

            if success {
                print(enabled ? "✅ 开机自启动已启用" : "❌ 开机自启动已禁用")
            } else {
                print("⚠️ 设置开机自启动失败")
            }
        }
    }

    /// 获取当前开机自启动状态
    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // 旧版本从 UserDefaults 读取状态
            return AppSettings.load().launchAtLogin
        }
    }
}
