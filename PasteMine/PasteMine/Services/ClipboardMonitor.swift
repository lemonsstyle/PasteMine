//
//  ClipboardMonitor.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import AppKit
import Combine

class ClipboardMonitor {
    var latestContent: String?
    
    private var timer: Timer?
    private var lastChangeCount: Int
    private var lastHash: String = ""
    private let pasteboard = NSPasteboard.general
    
    init() {
        lastChangeCount = pasteboard.changeCount
    }
    
    /// 启动剪贴板监听
    func start() {
        // 记录启动时的剪贴板状态，但不保存
        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            lastHash = HashUtility.sha256(content)
            print("📋 [启动] 已记录当前剪贴板状态（不保存）")
        }
        
        // 每 0.5 秒检查一次
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        
        print("✅ 剪贴板监听已启动")
    }
    
    /// 停止剪贴板监听
    func stop() {
        timer?.invalidate()
        timer = nil
        print("⏹️  剪贴板监听已停止")
    }
    
    /// 检查剪贴板变化
    private func checkClipboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        
        lastChangeCount = pasteboard.changeCount
        
        guard let content = pasteboard.string(forType: .string), !content.isEmpty else {
            return
        }
        
        let hash = HashUtility.sha256(content)
        
        // 与上次内容相同，跳过
        guard hash != lastHash else { return }
        
        lastHash = hash
        latestContent = content
        
        // 保存到数据库
        do {
            let appSource = getCurrentApp()
            try DatabaseService.shared.insertItem(content: content, appSource: appSource)
            
            // 发送通知
            NotificationService.shared.sendClipboardNotification(content: content)
        } catch {
            print("❌ 保存失败: \(error)")
        }
    }
    
    /// 获取当前活跃应用名称
    private func getCurrentApp() -> String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }
}

