//
//  ClipboardItem.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import Foundation
import CoreData

@objc(ClipboardItem)
public class ClipboardItem: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var content: String?
    @NSManaged public var contentHash: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var appSource: String?
}

extension ClipboardItem {
    static func fetchRequest() -> NSFetchRequest<ClipboardItem> {
        return NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
    }
}

