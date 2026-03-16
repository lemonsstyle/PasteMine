//
//  ClipboardMonitor.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import AppKit
import Combine
import UniformTypeIdentifiers

class ClipboardMonitor {
    var latestContent: String?

    // isPasting 标志位及超时保护
    var isPasting: Bool = false {
        didSet {
            if isPasting {
                isPastingSetTime = Date()
            } else {
                isPastingSetTime = nil
            }
        }
    }
    private var isPastingSetTime: Date?
    private let isPastingTimeout: TimeInterval = 2.0  // 2秒超时保护

    private var timer: Timer?
    private var lastChangeCount: Int
    private var lastHash: String = ""
    private let pasteboard = NSPasteboard.general
    private var isEnabled = false
    
    init() {
        lastChangeCount = pasteboard.changeCount
    }
    
    /// 启动剪贴板监听
    func start() {
        guard !isEnabled else { return }
        isEnabled = true
        
        // 记录启动时的剪贴板状态，但不保存
        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            lastHash = HashUtility.sha256(content)
            print("📋 [启动] 已记录当前剪贴板状态（不保存）")
        } else if let imagePayload = getImageDataFromPasteboard(allowPDF: true) {
            lastHash = HashUtility.sha256Data(imagePayload.data)
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
        guard isEnabled else { return }
        timer?.invalidate()
        timer = nil
        isEnabled = false
        print("⏹️  剪贴板监听已停止")
    }
    
    /// 根据开关状态自动控制监听
    func setMonitoringEnabled(_ enabled: Bool) {
        if enabled {
            start()
        } else {
            stop()
        }
    }
    
    /// 检查剪贴板变化
    private func checkClipboard() {
        guard isEnabled else { return }

        // 超时保护: 如果 isPasting 超过2秒，自动重置
        if isPasting, let setTime = isPastingSetTime,
           Date().timeIntervalSince(setTime) > isPastingTimeout {
            print("⚠️ isPasting 超时（超过\(isPastingTimeout)秒），自动重置")
            isPasting = false
        }

        guard pasteboard.changeCount != lastChangeCount else { return }

        lastChangeCount = pasteboard.changeCount

        // 如果正在执行粘贴操作，跳过通知但更新 hash
        if isPasting {
            print("📋 检测到粘贴操作，跳过复制通知")
            updateLastHash()
            return
        }
        
        // 全局忽略：敏感应用或类型
        if shouldIgnoreCurrentApp() {
            updateLastHash()
            return
        }
        
        if shouldIgnorePasteboardTypes() {
            print("⏭️  已根据剪贴板类型忽略本次内容")
            updateLastHash()
            return
        }

        let hasText = (pasteboard.string(forType: .string) ?? "").isEmpty == false
        let hasRasterImage = hasRasterImageData()
        let hasImageFileURL = hasImageFileURL()
        let hasPDF = pasteboard.data(forType: .pdf) != nil

        // 优先处理文件 URL 的图片（Finder 复制文件常见）或剪贴板中的位图数据
        // 当存在位图类图片（png/jpeg/tiff等）或图片文件 URL 时优先处理为图片
        // 对于仅提供 PDF 且无纯文本的情况，视为图片；若同时有文本，则优先文本
        if hasRasterImage || hasImageFileURL {
            if handleImage(allowPDF: false) { return }
        } else if hasPDF && !hasText {
            if handleImage(allowPDF: true) { return }
        }

        // 其次检查文本
        if hasText, let content = pasteboard.string(forType: .string), !content.isEmpty {
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
        
        // 检查应用是否在忽略列表中
        if shouldIgnoreCurrentApp() {
            lastHash = hash
            return
        }
        
        // 检查剪贴板类型
        if shouldIgnorePasteboardTypes() {
            print("⏭️  已忽略敏感类型")
            lastHash = hash
            return
        }
        
        lastHash = hash
        latestContent = content
        
        // 保存到数据库
        do {
            let currentApp = getCurrentApp()
            try DatabaseService.shared.insertTextItem(
                content: content,
                appSource: currentApp.displayName,
                appBundleId: currentApp.bundleId
            )
            
            // 发送通知
            NotificationService.shared.sendClipboardNotification(content: content, isImage: false)
        } catch {
            print("❌ 保存文本失败: \(error)")
        }
    }
    
    /// 处理图片内容
    @discardableResult
    private func handleImage(allowPDF: Bool = true) -> Bool {
        guard let imagePayload = getImageDataFromPasteboard(allowPDF: allowPDF) else { return false }

        let imageData = imagePayload.data
        let type = imagePayload.type

                // 使用原始数据的哈希值
                let hash = HashUtility.sha256Data(imageData)

                // 与上次内容相同，跳过
        guard hash != lastHash else { return true }

                // 检查应用是否在忽略列表中
                if shouldIgnoreCurrentApp() {
                    lastHash = hash
            return true
                }
                
                // 检查剪贴板类型
                if shouldIgnorePasteboardTypes() {
                    print("⏭️  已忽略敏感类型")
                    lastHash = hash
            return true
                }

                lastHash = hash
                latestContent = nil  // 图片不设置 latestContent

                // 保存原始数据到数据库（保持原画质）
                do {
                    let currentApp = getCurrentApp()
                    try DatabaseService.shared.insertImageItemRawData(
                        data: imageData,
                        type: type,
                        appSource: currentApp.displayName,
                        appBundleId: currentApp.bundleId
                    )

                    // 获取图片尺寸用于通知
                    let sizeText: String
                    if let dimensions = ImageStorageManager.shared.imageDimensions(from: imageData) {
                        sizeText = "\(dimensions.width)×\(dimensions.height)"
                    } else {
                        sizeText = "未知尺寸"
                    }

                    // 发送通知
            let formatText = formatText(for: type)
                    NotificationService.shared.sendClipboardNotification(content: "\(formatText) 图片 (\(sizeText))", isImage: true)

            print("✅ 已保存 \(formatText) 格式图片（原画质）")
        } catch {
            let nsError = error as NSError
            if nsError.domain == "ImageStorageManager", nsError.code == 2 {
                NotificationService.shared.sendClipboardSkippedNotification(reason: AppText.Notifications.skippedLargeImage)
                print("⚠️ Large image skipped: \(nsError.localizedDescription)")
            } else {
                print("❌ 保存图片失败: \(error)")
            }
        }

        return true
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
    
    /// 获取当前活跃应用信息 (Bundle ID, 显示名称)
    private func getCurrentApp() -> (bundleId: String?, displayName: String?) {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return (nil, nil)
        }
        return (app.bundleIdentifier, app.localizedName)
    }
    
    /// 检查当前应用是否应该被忽略
    private func shouldIgnoreCurrentApp() -> Bool {
        let settings = AppSettings.load()
        let currentApp = getCurrentApp()
        
        guard let bundleId = currentApp.bundleId else {
            return false
        }
        
        // 通过 Bundle ID 匹配
        let isIgnored = settings.ignoredApps.contains { $0.bundleId == bundleId }
        
        if isIgnored {
            print("⏭️  已忽略应用: \(currentApp.displayName ?? bundleId) (\(bundleId))")
        }
        
        return isIgnored
    }

    /// 更新 lastHash（用于粘贴操作时跳过通知但更新状态）
    private func updateLastHash() {
        // 尝试图片
        if let imagePayload = getImageDataFromPasteboard(allowPDF: true) {
            lastHash = HashUtility.sha256Data(imagePayload.data)
            latestContent = nil
            print("🖼️  已更新图片 hash（格式：\(formatText(for: imagePayload.type))）")
            return
        }

        // 尝试文本
        if let content = pasteboard.string(forType: .string), !content.isEmpty {
            lastHash = HashUtility.sha256(content)
            latestContent = content
            print("📋 已更新文本 hash")
            return
        }

        // 处理其他情况：使用 changeCount 生成唯一标识，防止状态不同步
        lastHash = "unknown-\(pasteboard.changeCount)"
        latestContent = nil
        print("⚠️ 未知内容类型，使用 changeCount 作为 hash")
    }
    
    /// 检查剪贴板类型是否应该被忽略
    private func shouldIgnorePasteboardTypes() -> Bool {
        let settings = AppSettings.load()
        guard settings.ignoreTypesEnabled else {
            return false
        }
        
        let types = pasteboard.types ?? []
        
        for type in types {
            if settings.ignoredPasteboardTypes.contains(type.rawValue) {
                print("⏭️  已忽略剪贴板类型: \(type.rawValue)")
                return true
            }
        }
        return false
    }

    /// 支持的图片类型（按优先级从文件 URL -> 数据类型）
    private var supportedImageTypes: [NSPasteboard.PasteboardType] {
        [
            .png,
            .tiff,
            .pdf,
            NSPasteboard.PasteboardType("public.jpeg"),
            NSPasteboard.PasteboardType("public.jpeg-2000"),
            NSPasteboard.PasteboardType("public.heic"),
            NSPasteboard.PasteboardType("public.heif"),
            NSPasteboard.PasteboardType("com.compuserve.gif"),
            NSPasteboard.PasteboardType("public.webp"),
            NSPasteboard.PasteboardType("com.microsoft.bmp")
        ]
    }

    /// 是否存在位图类图片数据（不含 PDF）
    private func hasRasterImageData() -> Bool {
        let rasterTypes: [NSPasteboard.PasteboardType] = [
            .png,
            .tiff,
            NSPasteboard.PasteboardType("public.jpeg"),
            NSPasteboard.PasteboardType("public.jpeg-2000"),
            NSPasteboard.PasteboardType("public.heic"),
            NSPasteboard.PasteboardType("public.heif"),
            NSPasteboard.PasteboardType("com.compuserve.gif"),
            NSPasteboard.PasteboardType("public.webp"),
            NSPasteboard.PasteboardType("com.microsoft.bmp")
        ]
        for type in rasterTypes {
            if pasteboard.data(forType: type) != nil {
                return true
            }
        }
        return false
    }

    /// 检查剪贴板中是否有图片文件 URL（Finder 复制的文件）
    private func hasImageFileURL() -> Bool {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] else {
            return false
        }

        for url in urls {
            // 仅处理文件且存在
            guard url.isFileURL,
                  FileManager.default.fileExists(atPath: url.path) else {
                continue
            }

            // 过滤目录
            if let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory, isDirectory {
                continue
            }

            // 判断是否为图片类型
            let contentType = (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType
                ?? UTType(filenameExtension: url.pathExtension)
            if let contentType, contentType.conforms(to: .image) {
                return true
            }
        }

        return false
    }

    /// 尝试从剪贴板提取图片数据（优先处理 Finder 文件 URL）
    private func getImageDataFromPasteboard(allowPDF: Bool) -> (data: Data, type: NSPasteboard.PasteboardType)? {
        // 1) Finder 复制的文件 URL
        if let fileResult = getImageDataFromFileURL(allowPDF: allowPDF) {
            return fileResult
        }

        // 2) 直接提供的图片二进制
        for type in supportedImageTypes {
            if !allowPDF, type == .pdf { continue }
            if let imageData = pasteboard.data(forType: type) {
                return (imageData, type)
            }
        }

        return nil
    }

    /// 从文件 URL（Finder）中获取图片
    private func getImageDataFromFileURL(allowPDF: Bool) -> (data: Data, type: NSPasteboard.PasteboardType)? {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] else {
            return nil
        }

        for url in urls {
            // 仅处理文件且存在
            guard url.isFileURL,
                  FileManager.default.fileExists(atPath: url.path) else {
                continue
            }

            // 过滤目录
            if let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory, isDirectory {
                continue
            }

            // 判断是否为图片类型
            let contentType = (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType
                ?? UTType(filenameExtension: url.pathExtension)
            guard let contentType, contentType.conforms(to: .image) else {
                continue
            }
            if !allowPDF, contentType == .pdf { continue }

            guard let data = try? Data(contentsOf: url) else {
                print("⚠️  读取文件失败: \(url.path)")
                continue
            }

            let pbType = NSPasteboard.PasteboardType(contentType.identifier)
            return (data: data, type: pbType)
        }

        return nil
    }

    /// 根据类型生成格式文本
    private func formatText(for type: NSPasteboard.PasteboardType) -> String {
        if let utType = UTType(type.rawValue) {
            if utType.conforms(to: .png) { return "PNG" }
            if utType.conforms(to: .jpeg) { return "JPEG" }
            if utType.conforms(to: .tiff) { return "TIFF" }
            if utType.conforms(to: .gif) { return "GIF" }
            if utType.conforms(to: .pdf) { return "PDF" }
            if let heif = UTType("public.heif"), utType.conforms(to: heif) { return "HEIF" }
            if let heic = UTType("public.heic"), utType.conforms(to: heic) { return "HEIC" }
            if let webp = UTType("public.webp"), utType.conforms(to: webp) { return "WEBP" }
            if let bmp = UTType("com.microsoft.bmp"), utType.conforms(to: bmp) { return "BMP" }
        }
        return type.rawValue.uppercased()
    }
}
