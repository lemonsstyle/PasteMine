//
//  WindowManager.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI
import AppKit

class WindowManager {
    private var window: NSWindow?
    private var previousApp: NSRunningApplication?
    
    init() {
        setupWindow()
    }
    
    /// 设置窗口
    private func setupWindow() {
        let contentView = ContentView()
            .environment(\.managedObjectContext, DatabaseService.shared.context)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window?.title = "剪贴板历史"
        window?.contentView = NSHostingView(rootView: contentView)
        window?.isReleasedWhenClosed = false
        window?.level = .floating  // 窗口置顶
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 初始位置：屏幕右上角
        if let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - 620
            let y = screen.visibleFrame.maxY - 520
            window?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        print("✅ 窗口已创建")
    }
    
    /// 显示窗口
    func show() {
        // 记录当前活跃应用
        previousApp = NSWorkspace.shared.frontmostApplication
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        print("👁️  窗口已显示")
    }
    
    /// 隐藏窗口
    func hide() {
        window?.orderOut(nil)
        
        // 恢复之前的应用（如果不是自动粘贴触发的）
        if let app = previousApp, app.processIdentifier != NSRunningApplication.current.processIdentifier {
            // 不自动切换，让 PasteService 控制
        }
        print("🙈 窗口已隐藏")
    }
    
    /// 切换窗口显示状态
    func toggle() {
        if window?.isVisible == true {
            hide()
        } else {
            show()
        }
    }
    
    /// 获取触发快捷键前的活跃应用
    func getPreviousApp() -> NSRunningApplication? {
        return previousApp
    }
}

