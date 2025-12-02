//
//  AppDelegate.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI
import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    static var shared: AppDelegate?

    var statusItem: NSStatusItem?
    var clipboardMonitor = ClipboardMonitor()
    var hotKeyManager: HotKeyManager?
    var windowManager: WindowManager?
    var onboardingWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置全局访问点
        AppDelegate.shared = self

        // 设置通知中心代理
        UNUserNotificationCenter.current().delegate = self

        // 检查是否是首次启动
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        if !hasCompletedOnboarding {
            // 首次启动，显示引导界面
            showOnboarding()
        } else {
            // 非首次启动，请求通知权限（如果还没授权的话）
            NotificationService.shared.requestPermission()
        }

        // 同步开机自启动状态
        let settings = AppSettings.load()
        LaunchAtLoginService.shared.setLaunchAtLogin(enabled: settings.launchAtLogin)

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

        // 启动剪贴板监听
        clipboardMonitor.start()
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
        // 检查是否需要清空历史记录
        let settings = AppSettings.load()
        if settings.clearOnQuit {
            do {
                try DatabaseService.shared.clearAll()
                print("✅ 已清空所有历史记录（退出时清空功能）")
            } catch {
                print("❌ 清空历史记录失败: \(error)")
            }
        }
        
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

    // MARK: - 引导界面

    private func showOnboarding() {
        let onboardingView = OnboardingView()
            .onDisappear {
                // 引导完成后，确保请求了必要的权限
                NotificationService.shared.requestPermission()
            }

        let hostingController = NSHostingController(rootView: onboardingView)

        onboardingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        onboardingWindow?.center()
        onboardingWindow?.contentViewController = hostingController
        onboardingWindow?.title = "欢迎使用 PasteMine"
        onboardingWindow?.titlebarAppearsTransparent = true
        onboardingWindow?.isMovableByWindowBackground = true
        onboardingWindow?.level = .floating

        // 监听窗口关闭
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: onboardingWindow,
            queue: .main
        ) { [weak self] _ in
            self?.onboardingWindow = nil
        }

        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// 在应用运行时也显示通知
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 即使应用在前台运行，也显示通知
        completionHandler([.banner, .sound])
    }
}

