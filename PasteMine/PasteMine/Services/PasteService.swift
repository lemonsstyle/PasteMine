//
//  PasteService.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import AppKit
import ApplicationServices

class PasteService {
    static let shared = PasteService()
    
    weak var windowManager: WindowManager?
    
    private init() {}
    
    /// 粘贴内容到活跃应用
    func paste(content: String) {
        // 1. 复制到剪贴板
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        print("📋 已复制到剪贴板: \(content.prefix(50))...")
        
        // 2. 隐藏窗口
        windowManager?.hide()
        
        // 3. 等待窗口隐藏后执行粘贴
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // 获取之前的应用并激活
            if let previousApp = self.windowManager?.getPreviousApp() {
                previousApp.activate(options: [])
                print("✅ 已激活应用: \(previousApp.localizedName ?? "未知")")
                
                // 等待应用激活后执行粘贴
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.simulatePaste()
                }
            } else {
                self.simulatePaste()
            }
        }
    }
    
    /// 模拟 Cmd+V 粘贴
    private func simulatePaste() {
        // 检查辅助功能权限
        guard NSApplication.shared.hasAccessibilityPermission else {
            print("⚠️  缺少辅助功能权限，无法自动粘贴")
            return
        }
        
        // 模拟 Cmd+V
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down: V (keyCode: 9)
        let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDownEvent?.flags = .maskCommand
        
        // Key up: V
        let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUpEvent?.flags = .maskCommand
        
        keyDownEvent?.post(tap: .cghidEventTap)
        keyUpEvent?.post(tap: .cghidEventTap)
        
        print("⌨️  已模拟 Cmd+V")
    }
}

