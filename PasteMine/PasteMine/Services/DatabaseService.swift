//
//  DatabaseService.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import CoreData
import Foundation

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
    
    /// 插入记录
    func insertItem(content: String, appSource: String? = nil) throws {
        let contentHash = HashUtility.sha256(content)
        
        // 检查是否已存在
        if try hashExists(contentHash) {
            print("📋 内容已存在，跳过")
            return
        }
        
        let item = ClipboardItem(context: context)
        item.id = UUID()
        item.content = content
        item.contentHash = contentHash
        item.createdAt = Date()
        item.appSource = appSource
        
        try context.save()
        print("✅ 新内容已保存: \(content.prefix(50))...")
        
        // 自动清理超出限制的记录
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
        context.delete(item)
        try context.save()
        print("🗑️  已删除记录")
    }
    
    /// 清空所有记录
    func clearAll() throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ClipboardItem")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try container.persistentStoreCoordinator.execute(deleteRequest, with: context)
        try context.save()
        context.reset() // 重置上下文以反映更改
        print("🗑️  已清空所有历史记录")
    }
    
    /// 限制记录数量
    private func trimToLimit(limit: Int = 100) throws {
        let request = ClipboardItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let items = try context.fetch(request)
        
        if items.count > limit {
            for item in items[limit...] {
                context.delete(item)
            }
            try context.save()
            print("🗑️  已清理 \(items.count - limit) 条超出限制的记录")
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

