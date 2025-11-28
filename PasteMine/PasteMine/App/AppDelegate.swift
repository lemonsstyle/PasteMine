//
//  AppDelegate.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    var statusItem: NSStatusItem?
    var clipboardMonitor = ClipboardMonitor()
    var hotKeyManager: HotKeyManager?
    var windowManager: WindowManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置全局访问点
        AppDelegate.shared = self

        // 隐藏 Dock 图标（已在 Info.plist 设置 LSUIElement）

        // 初始化窗口管理器
        windowManager = WindowManager()
        
        // 配置 PasteService
        PasteService.shared.windowManager = windowManager
        PasteService.shared.clipboardMonitor = clipboardMonitor

        // 创建托盘图标
        setupStatusBar()
        
        // 注册全局快捷键
        setupHotKey()
        
        // 启动时清空历史
        do {
            try DatabaseService.shared.clearAll()
            print("🗑️  启动时已清空历史记录")
        } catch {
            print("❌ 清空历史失败: \(error)")
        }
        
        // 启动剪贴板监听
        clipboardMonitor.start()
        
        // 请求辅助功能权限（会自动弹出系统提示）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 首次启动时，系统会自动弹出权限请求
            NSApplication.shared.requestAccessibilityPermission()
            
            // 如果用户拒绝了，显示自定义提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApplication.shared.checkAccessibilityPermission()
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        hotKeyManager?.unregister()
    }
    
    // MARK: - 托盘图标设置
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "剪贴板历史")
            button.action = #selector(toggleWindow)
            button.target = self
        }
        
        // 创建菜单
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "显示窗口", action: #selector(showWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        
        // 右键点击显示菜单
        if let button = statusItem?.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        print("✅ 托盘图标已创建")
    }
    
    @objc private func toggleWindow(_ sender: Any?) {
        // 检查是否是右键点击
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            statusItem?.menu = createMenu()
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
            return
        }
        
        windowManager?.toggle()
    }
    
    @objc private func showWindow() {
        windowManager?.show()
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "显示窗口", action: #selector(showWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        return menu
    }
    
    // MARK: - 全局快捷键设置
    
    private func setupHotKey() {
        hotKeyManager = HotKeyManager()
        hotKeyManager?.register { [weak self] in
            self?.windowManager?.toggle()
        }
    }
}

