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
        } else if let image = getImageFromPasteboard(), let imageData = image.tiffRepresentation {
            lastHash = HashUtility.sha256Data(imageData)
            print("🖼️  [启动] 已记录当前剪贴板图片（不保存）")
        }
        
        // 每 0.5 秒检查一次
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        
        print("✅ 剪贴板监听已启动（支持文本 + 图片）")
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
        
        // 优先检查图片（因为有些应用复制图片时也会同时复制文本）
        if let image = getImageFromPasteboard() {
            handleImage(image)
            return
        }
        
        // 其次检查文本
        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            handleText(content)
            return
        }
        
        print("📋 剪贴板内容不支持（仅支持文本和图片）")
    }
    
    /// 处理文本内容
    private func handleText(_ content: String) {
        let hash = HashUtility.sha256(content)
        
        // 与上次内容相同，跳过
        guard hash != lastHash else { return }
        
        lastHash = hash
        latestContent = content
        
        // 保存到数据库
        do {
            let appSource = getCurrentApp()
            try DatabaseService.shared.insertTextItem(content: content, appSource: appSource)
            
            // 发送通知
            NotificationService.shared.sendClipboardNotification(content: content, isImage: false)
        } catch {
            print("❌ 保存文本失败: \(error)")
        }
    }
    
    /// 处理图片内容
    private func handleImage(_ image: NSImage) {
        guard let imageData = image.tiffRepresentation else {
            print("❌ 无法获取图片数据")
            return
        }
        
        let hash = HashUtility.sha256Data(imageData)
        
        // 与上次内容相同，跳过
        guard hash != lastHash else { return }
        
        lastHash = hash
        latestContent = nil  // 图片不设置 latestContent
        
        // 保存到数据库
        do {
            let appSource = getCurrentApp()
            try DatabaseService.shared.insertImageItem(image: image, appSource: appSource)
            
            // 发送通知
            let size = "\(Int(image.size.width))×\(Int(image.size.height))"
            NotificationService.shared.sendClipboardNotification(content: "图片 (\(size))", isImage: true)
        } catch {
            print("❌ 保存图片失败: \(error)")
        }
    }
    
    /// 从剪贴板获取图片
    private func getImageFromPasteboard() -> NSImage? {
        // 尝试多种图片类型
        let imageTypes: [NSPasteboard.PasteboardType] = [
            .png, .tiff, .pdf
        ]
        
        for type in imageTypes {
            if let imageData = pasteboard.data(forType: type),
               let image = NSImage(data: imageData) {
                return image
            }
        }
        
        return nil
    }
    
    /// 获取当前活跃应用名称
    private func getCurrentApp() -> String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }
}

