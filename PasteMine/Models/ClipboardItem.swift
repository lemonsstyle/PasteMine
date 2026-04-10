//
//  ClipboardItem.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import Foundation
import CoreData
import AppKit
import ImageIO

/// 剪贴板内容类型
enum ClipboardItemType: String {
    case text = "text"
    case image = "image"
}

/// 展示用图片缓存（仅缓存下采样后的缩略图/预览图）
private let imageCache: NSCache<NSString, NSImage> = {
    let cache = NSCache<NSString, NSImage>()
    cache.countLimit = 40
    cache.totalCostLimit = 64 * 1024 * 1024
    return cache
}()

@objc(ClipboardItem)
public class ClipboardItem: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var content: String?
    @NSManaged public var contentHash: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var appSource: String?
    @NSManaged public var appBundleId: String?  // 应用 Bundle ID
    @NSManaged public var type: String?  // "text" 或 "image"
    @NSManaged public var imagePath: String?  // 图片文件路径
    @NSManaged public var imageWidth: Int32  // 图片宽度
    @NSManaged public var imageHeight: Int32  // 图片高度
    @NSManaged public var isPinned: Bool  // 是否固定
    @NSManaged public var pinnedAt: Date?  // 固定时间

    /// 获取类型枚举
    var itemType: ClipboardItemType {
        ClipboardItemType(rawValue: type ?? "text") ?? .text
    }

    /// 从文件路径推断图片格式
    var imageFormat: String? {
        guard itemType == .image, let path = imagePath else {
            return nil
        }
        let ext = (path as NSString).pathExtension.lowercased()
        return ext.isEmpty ? "png" : ext
    }

    /// 获取图片格式的 PasteboardType
    var pasteboardType: NSPasteboard.PasteboardType? {
        guard let format = imageFormat else {
            return nil
        }

        switch format {
        case "png":
            return .png
        case "jpg", "jpeg":
            return NSPasteboard.PasteboardType("public.jpeg")
        case "heic":
            return NSPasteboard.PasteboardType("public.heic")
        case "heif":
            return NSPasteboard.PasteboardType("public.heif")
        case "gif":
            return NSPasteboard.PasteboardType("com.compuserve.gif")
        case "webp":
            return NSPasteboard.PasteboardType("public.webp")
        case "bmp":
            return NSPasteboard.PasteboardType("com.microsoft.bmp")
        case "tiff", "tif":
            return .tiff
        case "pdf":
            return .pdf
        default:
            return .png  // 默认 PNG
        }
    }

    /// 获取图片原始数据（用于粘贴）
    var imageRawData: Data? {
        guard itemType == .image,
              let imagePath = imagePath,
              let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) else {
            return nil
        }
        return data
    }

    /// 获取原图对象（仅用于兜底流程，不应用于列表展示）
    var image: NSImage? {
        guard let path = imagePath, !path.isEmpty else {
            return nil
        }

        return NSImage(contentsOf: URL(fileURLWithPath: path))
    }

    /// 获取列表缩略图，避免把原图解码进 UI 常驻内存
    func thumbnailImage(maxPixelSize: Int = 160) -> NSImage? {
        loadDisplayImage(maxPixelSize: maxPixelSize)
    }

    /// 获取预览图，限制解码尺寸以控制峰值内存
    func previewImage(maxPixelSize: Int = 1024) -> NSImage? {
        loadDisplayImage(maxPixelSize: maxPixelSize)
    }

    /// 从缓存中移除此图片
    func removeImageFromCache() {
        guard let path = imagePath else { return }
        for maxPixelSize in [160, 1024] {
            imageCache.removeObject(forKey: "\(path)#\(maxPixelSize)" as NSString)
        }
    }

    /// 清空所有图片缓存
    static func clearImageCache() {
        imageCache.removeAllObjects()
    }

    /// 获取显示文本
    var displayText: String {
        switch itemType {
        case .text:
            return content ?? ""
        case .image:
            let formatText = imageFormat?.uppercased() ?? "IMAGE"
            return "[\(imageWidth) × \(imageHeight) \(formatText)]"
        }
    }
}

private extension ClipboardItem {
    func loadDisplayImage(maxPixelSize: Int) -> NSImage? {
        guard let path = imagePath, !path.isEmpty else {
            return nil
        }

        let cacheKey = "\(path)#\(maxPixelSize)" as NSString
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }

        let fileURL = URL(fileURLWithPath: path)
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let image = NSImage(
            cgImage: cgImage,
            size: NSSize(width: cgImage.width, height: cgImage.height)
        )
        let cost = max(cgImage.bytesPerRow * cgImage.height, cgImage.width * cgImage.height * 4)
        imageCache.setObject(image, forKey: cacheKey, cost: cost)
        return image
    }
}

extension ClipboardItem {
    static func fetchRequest() -> NSFetchRequest<ClipboardItem> {
        return NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
    }
}
