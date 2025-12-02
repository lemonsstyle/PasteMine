//
//  WindowManager.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI
import AppKit

class WindowManager: NSObject {
    private var window: NSWindow?
    private var previousApp: NSRunningApplication?
    private var clickOutsideMonitor: Any?
    private var isAutoHidePaused = false
    
    override init() {
        super.init()
        setupWindow()
    }
    
    /// 设置窗口
    private func setupWindow() {
        let contentView = ContentView()
            .environment(\.managedObjectContext, DatabaseService.shared.context)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window?.title = "剪贴板历史"
        window?.contentView = NSHostingView(rootView: contentView)
        window?.isReleasedWhenClosed = false
        window?.level = .floating  // 窗口置顶
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Add Liquid Glass window properties
        if #available(macOS 14, *) {
            window?.isOpaque = false
            window?.backgroundColor = .clear
            window?.titlebarAppearsTransparent = true
            window?.toolbarStyle = .unified
        } else {
            window?.backgroundColor = NSColor.windowBackgroundColor
        }
        
        // 设置代理以监听窗口事件
        window?.delegate = self
        
        print("✅ 窗口已创建")
    }
    
    /// 显示窗口
    func show() {
        // 记录当前活跃应用
        previousApp = NSWorkspace.shared.frontmostApplication
        
        // 计算窗口位置（跟随鼠标）
        positionWindowNearMouse()
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // 启动点击外部监听
        startClickOutsideMonitor()
        
        // 通知列表滚动到顶部（显示最新内容）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .scrollToTop, object: nil)
        }
        
        print("👁️  窗口已显示在鼠标附近，已滚动到顶部")
    }
    
    /// 隐藏窗口
    func hide() {
        window?.orderOut(nil)
        
        // 停止点击外部监听
        stopClickOutsideMonitor()
        
        // 恢复之前的应用（如果不是自动粘贴触发的）
        if let app = previousApp, app.processIdentifier != NSRunningApplication.current.processIdentifier {
            // 不自动切换，让 PasteService 控制
        }
        print("🙈 窗口已隐藏")
    }
    
    /// 将焦点重新聚焦到窗口
    func refocus() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// 暂停点击外部自动隐藏
    func pauseAutoHide() {
        isAutoHidePaused = true
    }
    
    /// 恢复点击外部自动隐藏
    func resumeAutoHide() {
        isAutoHidePaused = false
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
    
    // MARK: - 窗口位置计算
    
    /// 将窗口定位在鼠标附近
    private func positionWindowNearMouse() {
        guard let window = window, let screen = NSScreen.main else { return }
        
        // 获取鼠标位置（屏幕坐标）
        let mouseLocation = NSEvent.mouseLocation
        
        // 窗口尺寸
        let windowWidth: CGFloat = 600
        let windowHeight: CGFloat = 500
        let margin: CGFloat = 20  // 与鼠标的间距
        
        // 计算候选位置（优先右侧）
        var x = mouseLocation.x + margin
        var y = mouseLocation.y - windowHeight / 2  // 垂直居中于鼠标
        
        // 检查右侧是否有足够空间
        if x + windowWidth > screen.visibleFrame.maxX {
            // 右侧空间不足，放在左侧
            x = mouseLocation.x - windowWidth - margin
        }
        
        // 检查左侧是否超出屏幕
        if x < screen.visibleFrame.minX {
            // 左侧也不够，居中显示
            x = mouseLocation.x - windowWidth / 2
        }
        
        // 确保不超出屏幕边界
        x = max(screen.visibleFrame.minX, min(x, screen.visibleFrame.maxX - windowWidth))
        y = max(screen.visibleFrame.minY, min(y, screen.visibleFrame.maxY - windowHeight))
        
        // 设置窗口位置
        window.setFrameOrigin(NSPoint(x: x, y: y))
        
        print("📍 窗口位置: (\(Int(x)), \(Int(y))), 鼠标: (\(Int(mouseLocation.x)), \(Int(mouseLocation.y)))")
    }
    
    // MARK: - 点击外部关闭
    
    /// 启动点击外部监听
    private func startClickOutsideMonitor() {
        // 移除旧的监听器
        stopClickOutsideMonitor()
        
        // 监听全局鼠标点击事件
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handleClickOutside(event)
        }
        
        // 同时监听本地事件（窗口内的点击）
        // 这样可以正确处理窗口内外的点击
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            // 如果点击在窗口内，不关闭
            if let window = self?.window, window.isVisible {
                let clickLocation = event.locationInWindow
                let windowBounds = window.contentView?.bounds ?? .zero
                
                if windowBounds.contains(clickLocation) {
                    // 点击在窗口内，正常处理
                    return event
                }
            }
            return event
        }
    }
    
    /// 停止点击外部监听
    private func stopClickOutsideMonitor() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }
    
    /// 处理点击外部事件
    private func handleClickOutside(_ event: NSEvent) {
        guard let window = window, window.isVisible else { return }
        guard !isAutoHidePaused else { return }
        
        // 获取点击位置（屏幕坐标）
        let clickLocation = NSEvent.mouseLocation
        
        // 获取窗口的屏幕坐标范围
        let windowFrame = window.frame
        
        // 判断点击是否在窗口外部
        if !windowFrame.contains(clickLocation) {
            print("🖱️  点击外部，关闭窗口")
            hide()
        }
    }
    
    deinit {
        stopClickOutsideMonitor()
    }
}

// MARK: - NSWindowDelegate

extension WindowManager: NSWindowDelegate {
    /// 窗口失去焦点时（可选：也可以关闭窗口）
    func windowDidResignKey(_ notification: Notification) {
        // 可以选择在失去焦点时关闭，但可能体验不好
        // hide()
    }
}

