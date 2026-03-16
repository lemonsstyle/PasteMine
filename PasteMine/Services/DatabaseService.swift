//
//  DatabaseService.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import CoreData
import Foundation
import AppKit

class DatabaseService {
    static let shared = DatabaseService()
    
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "PasteMine")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data 加载失败: \(error)")
            }
            print("✅ Core Data 已加载")
        }
        
        // 配置自动合并策略
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    /// 插入文本记录
    func insertTextItem(content: String, appSource: String? = nil, appBundleId: String? = nil) throws {
        let contentHash = HashUtility.sha256(content)
        
        // 检查是否已存在
        if try hashExists(contentHash) {
            print("📋 文本内容已存在，跳过")
            return
        }
        
        let item = ClipboardItem(context: context)
        item.id = UUID()
        item.type = ClipboardItemType.text.rawValue
        item.content = content
        item.contentHash = contentHash
        item.createdAt = Date()
        item.appSource = appSource
        item.appBundleId = appBundleId
        
        try context.save()
        print("✅ 新文本已保存: \(content.prefix(50))...")

        // 自动清理
        try trimToLimit()
    }
    
    /// 插入图片记录（使用原始数据，保持原画质）
    func insertImageItemRawData(data: Data, type: NSPasteboard.PasteboardType, appSource: String? = nil, appBundleId: String? = nil) throws {
        // 保存图片原始数据到文件系统
        let result = try ImageStorageManager.shared.saveImageRawData(data, type: type)

        // 检查是否已存在
        if try hashExists(result.hash) {
            print("🖼️  图片已存在，跳过")
            return
        }

        let item = ClipboardItem(context: context)
        item.id = UUID()
        item.type = ClipboardItemType.image.rawValue
        item.content = nil
        item.contentHash = result.hash
        item.imagePath = result.path
        item.imageWidth = Int32(result.width)
        item.imageHeight = Int32(result.height)
        item.createdAt = Date()
        item.appSource = appSource
        item.appBundleId = appBundleId

        try context.save()
        print("✅ 新图片已保存（原画质，格式：\(result.format.uppercased())）: \(result.width)×\(result.height)")

        // 自动清理
        try trimToLimit()
    }

    /// 插入图片记录（兼容旧接口，已弃用）
    @available(*, deprecated, message: "使用 insertImageItemRawData(_:type:appSource:) 保持原画质")
    func insertImageItem(image: NSImage, appSource: String? = nil) throws {
        // 保存图片到文件系统
        let result = try ImageStorageManager.shared.saveImage(image)

        // 检查是否已存在
        if try hashExists(result.hash) {
            print("🖼️  图片已存在，跳过")
            return
        }

        let item = ClipboardItem(context: context)
        item.id = UUID()
        item.type = ClipboardItemType.image.rawValue
        item.content = nil
        item.contentHash = result.hash
        item.imagePath = result.path
        item.imageWidth = Int32(result.width)
        item.imageHeight = Int32(result.height)
        item.createdAt = Date()
        item.appSource = appSource

        try context.save()
        print("✅ 新图片已保存: \(result.width)×\(result.height)")

        // 自动清理
        try trimToLimit()
    }
    
    /// 查询所有记录
    func fetchAll() throws -> [ClipboardItem] {
        let request = ClipboardItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return try context.fetch(request)
    }
    
    /// 搜索记录
    func search(keyword: String) throws -> [ClipboardItem] {
        let request = ClipboardItem.fetchRequest()
        request.predicate = NSPredicate(format: "content CONTAINS[cd] %@", keyword)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return try context.fetch(request)
    }
    
    /// 删除单条记录
    func delete(_ item: ClipboardItem) throws {
        // 如果是图片，删除文件
        if item.itemType == .image, let imagePath = item.imagePath {
            item.removeImageFromCache()
            ImageStorageManager.shared.deleteImage(at: imagePath)
        }
        
        context.delete(item)
        try context.save()
        print("🗑️  已删除记录")
    }
    
    /// 清空所有记录
    func clearAll() throws {
        // 获取所有记录
        let request = ClipboardItem.fetchRequest()
        let allItems = try context.fetch(request)

        // 逐个删除（这样会正确触发 SwiftUI 的 @FetchRequest 更新）
        for item in allItems {
            // 如果是图片，删除文件
            if item.itemType == .image, let imagePath = item.imagePath {
                item.removeImageFromCache()
                ImageStorageManager.shared.deleteImage(at: imagePath)
            }
            context.delete(item)
        }

        try context.save()
        print("🗑️  已清空所有历史记录")
    }

    /// 限制记录数量（根据设置中的数量上限）
    private func trimToLimit() throws {
        let settings = AppSettings.load()

        // 🎉 所有用户都可以使用完整历史记录功能
        let limit = settings.proMaxHistoryCount  // 使用用户设置的上限（200/999）

        let request = ClipboardItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let allItems = try context.fetch(request)

        // 🔧 修复：分离固定和未固定的消息
        let pinnedItems = allItems.filter { $0.isPinned }
        let unpinnedItems = allItems.filter { !$0.isPinned }

        // 固定的消息不计入数量限制，只对未固定的消息应用限制
        if unpinnedItems.count > limit {
            // 删除超出限制的未固定记录（从最旧的开始删除）
            let itemsToDelete = unpinnedItems[limit...]

            for item in itemsToDelete {
                // 删除图片文件
                if item.itemType == .image, let imagePath = item.imagePath {
                    item.removeImageFromCache()
                    ImageStorageManager.shared.deleteImage(at: imagePath)
                }
                context.delete(item)
            }
            try context.save()
            print("🗑️  已清理 \(itemsToDelete.count) 条超出数量限制的记录（上限: \(limit)，固定消息: \(pinnedItems.count) 条已保留）")
        }
    }
    
    /// 检查哈希是否存在
    private func hashExists(_ contentHash: String) throws -> Bool {
        let request = ClipboardItem.fetchRequest()
        request.predicate = NSPredicate(format: "contentHash == %@", contentHash)
        request.fetchLimit = 1
        return try context.count(for: request) > 0
    }
}
