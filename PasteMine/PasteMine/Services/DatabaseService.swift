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
    func insertTextItem(content: String, appSource: String? = nil) throws {
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
        
        try context.save()
        print("✅ 新文本已保存: \(content.prefix(50))...")
        
        // 自动清理
        try cleanExpiredItems()
        try trimToLimit()
    }
    
    /// 插入图片记录
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
        try cleanExpiredItems()
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
            ImageStorageManager.shared.deleteImage(at: imagePath)
        }
        
        context.delete(item)
        try context.save()
        print("🗑️  已删除记录")
    }
    
    /// 清空所有记录
    func clearAll() throws {
        // 先获取所有图片记录并删除文件
        let request = ClipboardItem.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", ClipboardItemType.image.rawValue)
        let imageItems = try context.fetch(request)
        
        for item in imageItems {
            if let imagePath = item.imagePath {
                ImageStorageManager.shared.deleteImage(at: imagePath)
            }
        }
        
        // 批量删除所有记录
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: "ClipboardItem"))
        try container.persistentStoreCoordinator.execute(deleteRequest, with: context)
        try context.save()
        context.reset() // 重置上下文以反映更改
        
        print("🗑️  已清空所有历史记录")
    }
    
    /// 清理过期记录（根据设置中的保留天数）
    private func cleanExpiredItems() throws {
        let settings = AppSettings.load()
        
        // retentionDays = 0 表示永久保存
        guard settings.retentionDays > 0 else { return }
        
        // 计算过期日期
        let calendar = Calendar.current
        guard let expirationDate = calendar.date(byAdding: .day, value: -settings.retentionDays, to: Date()) else {
            return
        }
        
        // 查询过期的记录
        let request = ClipboardItem.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt < %@", expirationDate as NSDate)
        
        let expiredItems = try context.fetch(request)
        
        if !expiredItems.isEmpty {
            // 删除图片文件
            for item in expiredItems {
                if item.itemType == .image, let imagePath = item.imagePath {
                    ImageStorageManager.shared.deleteImage(at: imagePath)
                }
                context.delete(item)
            }
            try context.save()
            print("🗑️  已清理 \(expiredItems.count) 条过期记录（超过 \(settings.retentionDays) 天）")
        }
    }
    
    /// 限制记录数量（根据设置中的数量上限）
    private func trimToLimit() throws {
        let settings = AppSettings.load()
        let limit = settings.maxHistoryCount
        
        let request = ClipboardItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let items = try context.fetch(request)
        
        if items.count > limit {
            // 删除超出限制的记录
            for item in items[limit...] {
                // 删除图片文件
                if item.itemType == .image, let imagePath = item.imagePath {
                    ImageStorageManager.shared.deleteImage(at: imagePath)
                }
                context.delete(item)
            }
            try context.save()
            print("🗑️  已清理 \(items.count - limit) 条超出数量限制的记录（上限: \(limit)）")
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

