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
    var isPasting: Bool = false  // 标记是否正在执行粘贴操作

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

        // 如果正在执行粘贴操作，跳过通知但更新 hash
        if isPasting {
            print("📋 检测到粘贴操作，跳过复制通知")
            updateLastHash()
            return
        }

        // 优先检查图片（因为有些应用复制图片时也会同时复制文本）
        // 检查是否有图片数据
        if pasteboard.data(forType: .png) != nil ||
           pasteboard.data(forType: .tiff) != nil ||
           pasteboard.data(forType: .pdf) != nil {
            handleImage()
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
    private func handleImage() {
        // 尝试多种图片类型，保存原始数据
        let imageTypes: [NSPasteboard.PasteboardType] = [
            .png, .tiff, .pdf
        ]

        for type in imageTypes {
            if let imageData = pasteboard.data(forType: type) {
                // 使用原始数据的哈希值
                let hash = HashUtility.sha256Data(imageData)

                // 与上次内容相同，跳过
                guard hash != lastHash else { return }

                lastHash = hash
                latestContent = nil  // 图片不设置 latestContent

                // 保存原始数据到数据库（保持原画质）
                do {
                    let appSource = getCurrentApp()
                    try DatabaseService.shared.insertImageItemRawData(data: imageData, type: type, appSource: appSource)

                    // 获取图片尺寸用于通知
                    var sizeText = ""
                    if let image = NSImage(data: imageData) {
                        sizeText = "\(Int(image.size.width))×\(Int(image.size.height))"
                    } else {
                        sizeText = "未知尺寸"
                    }

                    // 发送通知
                    let formatText = type == .png ? "PNG" : type == .tiff ? "TIFF" : "PDF"
                    NotificationService.shared.sendClipboardNotification(content: "\(formatText) 图片 (\(sizeText))", isImage: true)

                    print("✅ 已保存 \(formatText) 格式图片（原画质）")
                } catch {
                    print("❌ 保存图片失败: \(error)")
                }

                return
            }
        }

        print("📋 剪贴板中没有支持的图片格式")
    }

    /// 从剪贴板获取图片（已弃用，仅用于兼容）
    @available(*, deprecated, message: "使用 handleImage() 直接处理原始数据")
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

    /// 更新 lastHash（用于粘贴操作时跳过通知但更新状态）
    private func updateLastHash() {
        // 优先检查图片（使用原始数据）
        let imageTypes: [NSPasteboard.PasteboardType] = [.png, .tiff, .pdf]
        for type in imageTypes {
            if let imageData = pasteboard.data(forType: type) {
                lastHash = HashUtility.sha256Data(imageData)
                latestContent = nil
                print("🖼️  已更新图片 hash（格式：\(type == .png ? "PNG" : type == .tiff ? "TIFF" : "PDF")）")
                return
            }
        }

        // 其次检查文本
        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            lastHash = HashUtility.sha256(content)
            latestContent = content
            print("📋 已更新文本 hash")
            return
        }
    }
}

