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
    
    static var isLaunchAtLoginSupported: Bool {
        if #available(macOS 13.0, *) {
            return true
        }
        return false
    }

    private init() {}

    /// 设置开机自启动状态
    func setLaunchAtLogin(enabled: Bool) {
        guard LaunchAtLoginService.isLaunchAtLoginSupported else {
            print("ℹ️ 开机自启动仅支持 macOS 13+，已忽略该设置")
            return
        }
        
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
        }
    }

    /// 获取当前开机自启动状态
    func isLaunchAtLoginEnabled() -> Bool {
        guard LaunchAtLoginService.isLaunchAtLoginSupported else { return false }
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
}
