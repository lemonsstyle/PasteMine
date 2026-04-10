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
    weak var clipboardMonitor: ClipboardMonitor?  // 引用 ClipboardMonitor
    private var currentPasteItem: ClipboardItem?

    private init() {}
    
    /// 粘贴剪贴板项到活跃应用
    func paste(item: ClipboardItem) {
        guard writeToPasteboard(item) else {
            return
        }

        // 保存当前粘贴项（用于后续通知）
        self.currentPasteItem = item

        // 设置粘贴标记，防止 ClipboardMonitor 发送重复通知
        clipboardMonitor?.isPasting = true
        
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
    
    /// 粘贴文本内容（兼容旧接口）
    @available(*, deprecated, message: "使用 paste(item:) 代替")
    func paste(content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        print("📋 已复制到剪贴板（\(content.count) 个字符）")
        
        windowManager?.hide()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if let previousApp = self.windowManager?.getPreviousApp() {
                previousApp.activate(options: [])
                print("✅ 已激活应用: \(previousApp.localizedName ?? "未知")")
                
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
            print("⚠️  缺少辅助功能权限，无法自动粘贴（已降级为复制）")
            NotificationService.shared.sendAccessibilityPermissionWarning()
            currentPasteItem = nil
            AppDelegate.shared?.clipboardMonitor.isPasting = false
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

        // 发送粘贴通知
        if let item = self.currentPasteItem {
            let isImage = item.itemType == .image
            let notificationContent = item.itemType == .text
                ? (item.content ?? "")
                : "图片 \(item.imageWidth)×\(item.imageHeight)"

            NotificationService.shared.sendPasteNotification(
                content: notificationContent,
                isImage: isImage
            )

            // 清理临时引用
            self.currentPasteItem = nil
        }

        // 延迟清除粘贴标记，确保 ClipboardMonitor 有足够时间检测到粘贴状态
        // ClipboardMonitor 每 0.5 秒检查一次，所以延迟 0.6 秒清除标记
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 直接通过 AppDelegate 访问，避免 weak reference 失效导致清除失败
            AppDelegate.shared?.clipboardMonitor.isPasting = false
            print("✅ 已清除粘贴标记")
        }
    }

    @discardableResult
    private func writeToPasteboard(_ item: ClipboardItem) -> Bool {
        let pasteboard = NSPasteboard.general

        switch item.itemType {
        case .text:
            guard let content = item.content, !content.isEmpty else {
                print("⚠️ 选中的文本记录为空，已取消粘贴")
                return false
            }

            pasteboard.clearContents()
            pasteboard.setString(content, forType: .string)
            print("📋 已复制文本到剪贴板（\(content.count) 个字符）")
            return true

        case .image:
            if let rawData = item.imageRawData,
               let pasteboardType = item.pasteboardType {
                pasteboard.clearContents()

                var wroteFileURL = false
                if let imagePath = item.imagePath {
                    let fileURL = URL(fileURLWithPath: imagePath)
                    if FileManager.default.fileExists(atPath: imagePath) {
                        pasteboard.writeObjects([fileURL as NSURL])
                        wroteFileURL = true
                    }
                }

                pasteboard.setData(rawData, forType: pasteboardType)
                let formatText = item.imageFormat?.uppercased() ?? "IMAGE"
                print("🖼️ 已复制图片到剪贴板（格式：\(formatText)，文件 URL: \(wroteFileURL ? "已写入" : "未写入")）: \(item.imageWidth)×\(item.imageHeight)")
                return true
            }

            if let image = item.image {
                pasteboard.clearContents()
                pasteboard.writeObjects([image])
                print("⚠️ 使用 NSImage 复制图片（可能损失画质）: \(item.imageWidth)×\(item.imageHeight)")
                return true
            }

            print("⚠️ 图片源文件不可用，已取消粘贴以避免清空当前剪贴板")
            return false
        }
    }
}
