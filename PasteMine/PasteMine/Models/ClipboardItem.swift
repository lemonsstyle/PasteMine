//
//  ClipboardItem.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import Foundation
import CoreData
import AppKit

/// 剪贴板内容类型
enum ClipboardItemType: String {
    case text = "text"
    case image = "image"
}

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

    /// 获取图片对象（如果是图片类型，仅用于显示）
    var image: NSImage? {
        guard let data = imageRawData else {
            return nil
        }
        return NSImage(data: data)
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

extension ClipboardItem {
    static func fetchRequest() -> NSFetchRequest<ClipboardItem> {
        return NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
    }
}

