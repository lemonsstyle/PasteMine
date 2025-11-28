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

        // 设置通知中心代理 - 这对于后台应用很重要!
        UNUserNotificationCenter.current().delegate = self

        // 隐藏 Dock 图标(已在 Info.plist 设置 LSUIElement)

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
            print("🗑️ 启动时已清空历史记录")
        } catch {
            print("❌ 清空历史失败: \(error)")
        }

        // 启动剪贴板监听
        clipboardMonitor.start()

        // 检查是否首次启动
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        if !hasCompletedOnboarding {
            // 首次启动,显示引导页面
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showOnboarding()
            }
        } else {
            // 非首次启动,静默请求权限
            requestPermissionsIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        hotKeyManager?.unregister()
    }

    // MARK: - UNUserNotificationCenterDelegate

    // 当应用在前台时也显示通知
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 即使应用在前台也显示通知
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    // MARK: - 首次启动引导

    func showOnboarding() {
        let onboardingView = OnboardingView()
        let hostingController = NSHostingController(rootView: onboardingView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "欢迎使用 PasteMine"
        window.styleMask = [.titled, .closable]
        window.center()
        window.level = .floating
        window.makeKeyAndOrderFront(nil)

        self.onboardingWindow = window

        NSApp.activate(ignoringOtherApps: true)
    }

    private func requestPermissionsIfNeeded() {
        // 请求通知权限
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        print("✅ 通知权限已授予")
                    } else if let error = error {
                        print("❌ 通知权限请求失败: \(error)")
                    } else {
                        print("⚠️ 通知权限被拒绝")
                    }
                }
            }
        }

        // 检查辅助功能权限
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("⚠️ 辅助功能权限未授予,某些功能可能无法正常工作")
        }
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
