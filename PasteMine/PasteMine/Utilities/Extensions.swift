//
//  Extensions.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import AppKit
import ApplicationServices

extension NSApplication {
    /// 检查是否拥有辅助功能权限
    var hasAccessibilityPermission: Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// 检查并提示用户授予辅助功能权限
    func checkAccessibilityPermission() {
        if !hasAccessibilityPermission {
            let alert = NSAlert()
            alert.messageText = AppText.Accessibility.permissionRequired
            alert.informativeText = AppText.Accessibility.permissionMessage
            alert.alertStyle = .informational
            alert.addButton(withTitle: AppText.Accessibility.openSystemPreferences)
            alert.addButton(withTitle: AppText.Accessibility.later)
            
            if alert.runModal() == .alertFirstButtonReturn {
                // 尝试多种方式打开系统设置
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                } else {
                    // 备用方案
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
                }
            }
        }
    }
    
    /// 请求辅助功能权限（会弹出系统提示）
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let _ = AXIsProcessTrustedWithOptions(options)
    }

    /// 检查是否已授予辅助功能权限（不弹窗）
    func isAccessibilityPermissionGranted() -> Bool {
        return hasAccessibilityPermission
    }
}

