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
    @NSManaged public var type: String?  // "text" 或 "image"
    @NSManaged public var imagePath: String?  // 图片文件路径
    @NSManaged public var imageWidth: Int32  // 图片宽度
    @NSManaged public var imageHeight: Int32  // 图片高度
    
    /// 获取类型枚举
    var itemType: ClipboardItemType {
        ClipboardItemType(rawValue: type ?? "text") ?? .text
    }
    
    /// 获取图片对象（如果是图片类型）
    var image: NSImage? {
        guard itemType == .image,
              let imagePath = imagePath,
              let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) else {
            return nil
        }
        return NSImage(data: imageData)
    }
    
    /// 获取显示文本
    var displayText: String {
        switch itemType {
        case .text:
            return content ?? ""
        case .image:
            return "[\(imageWidth) × \(imageHeight) 图片]"
        }
    }
}

extension ClipboardItem {
    static func fetchRequest() -> NSFetchRequest<ClipboardItem> {
        return NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
    }
}

