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

    // ⚠️ 添加标志：用户是否真的想退出
    private var isQuitting = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置全局访问点
        AppDelegate.shared = self

        // 设置通知中心代理（必须在请求权限之前设置）
        UNUserNotificationCenter.current().delegate = self

        // 同步开机自启动状态
        let settings = AppSettings.load()
        LaunchAtLoginService.shared.setLaunchAtLogin(enabled: settings.launchAtLogin)
        
        // 检查 Pro 状态（包括试用状态）
        Task { @MainActor in
            ProEntitlementManager.shared.recalcState()
        }

        // 隐藏 Dock 图标（已在 Info.plist 设置 LSUIElement）

        // ⚠️ 先初始化窗口管理器和托盘图标，确保应用有可见的 UI
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
        
        // 检查是否是首次启动（在其他初始化完成后进行）
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        if !hasCompletedOnboarding {
            // 首次启动，显示引导界面
            print("🆕 首次启动，显示引导界面")
            showOnboarding()
        } else {
            // 非首次启动，请求通知权限（如果还没授权的话）
            print("✅ 非首次启动，检查通知权限")

            // ⚠️ 关键修改：确保应用激活后再请求权限
            NSApp.activate(ignoringOtherApps: true)

            // 延迟一小段时间，确保应用和托盘图标已完全初始化
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationService.shared.requestPermission()
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        hotKeyManager?.unregister()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // 应用返回前台时，重新计算 Pro 状态
        Task { @MainActor in
            ProEntitlementManager.shared.recalcState()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 对于 LSUIElement = true 的应用，关闭最后一个窗口不应该终止应用
        // 因为托盘图标应该继续存在
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        print("⚠️ applicationShouldTerminate 被调用")

        // 如果是用户主动退出，允许终止
        if isQuitting {
            print("✅ 用户主动退出，允许终止")
            return .terminateNow
        }

        // 否则阻止意外终止
        if statusItem != nil {
            print("✅ 托盘图标存在，阻止意外终止")
            return .terminateCancel
        }

        return .terminateNow
    }


    // MARK: - 托盘图标设置
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: AppText.Menu.clipboardHistory)
            button.action = #selector(toggleWindow)
            button.target = self
        }
        
        // 创建菜单
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: AppText.Menu.showWindow, action: #selector(showWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: AppText.Menu.quit, action: #selector(quit), keyEquivalent: "q"))
        
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
        print("🚪 用户请求退出应用")

        // 设置退出标志
        isQuitting = true

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
        menu.addItem(NSMenuItem(title: AppText.Menu.showWindow, action: #selector(showWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: AppText.Menu.quit, action: #selector(quit), keyEquivalent: "q"))
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
        // ⚠️ 移除 onDisappear 闭包，避免窗口关闭时的内存管理问题
        // 权限请求已在 completeOnboarding 后通过其他方式处理
        let onboardingView = OnboardingView()

        let hostingController = NSHostingController(rootView: onboardingView)

        onboardingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        onboardingWindow?.setContentSize(NSSize(width: 600, height: 700))

        onboardingWindow?.center()
        onboardingWindow?.contentViewController = hostingController
        onboardingWindow?.title = AppText.Onboarding.title
        onboardingWindow?.titlebarAppearsTransparent = true
        onboardingWindow?.isMovableByWindowBackground = true
        onboardingWindow?.level = .floating

        // ⚠️ 关键：确保窗口不会在关闭时立即释放
        onboardingWindow?.isReleasedWhenClosed = false

        // 监听窗口关闭
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: onboardingWindow,
            queue: .main
        ) { [weak self] _ in
            print("🔔 引导窗口即将关闭")
            // 延迟清理，避免立即释放导致崩溃
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.onboardingWindow = nil
                print("✅ 引导窗口已清理")
            }
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

