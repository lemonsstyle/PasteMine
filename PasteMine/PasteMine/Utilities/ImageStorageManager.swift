//
//  ImageStorageManager.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/23.
//

import Foundation
import AppKit
import CryptoKit

class ImageStorageManager {
    static let shared = ImageStorageManager()
    
    private let storageDirectory: URL
    private let maxImageSize: Int64 = 10 * 1024 * 1024 // 10MB 默认限制
    
    private init() {
        // 创建存储目录：~/Library/Application Support/PasteMine/images/
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        storageDirectory = appSupport.appendingPathComponent("PasteMine/images", isDirectory: true)
        
        // 确保目录存在
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        
        print("📁 图片存储目录: \(storageDirectory.path)")
    }
    
    /// 保存图片并返回文件路径
    func saveImage(_ image: NSImage) throws -> (path: String, hash: String, width: Int, height: Int) {
        // 获取图片的 TIFF 表示
        guard let tiffData = image.tiffRepresentation else {
            throw NSError(domain: "ImageStorageManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法获取图片数据"])
        }

        // 检查图片大小（20MB 限制）
        let settings = AppSettings.load()
        let imageSizeMB = Double(tiffData.count) / 1024 / 1024

        if settings.ignoreLargeImages && imageSizeMB > 20 {
            throw NSError(domain: "ImageStorageManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "图片大小超过 20MB 限制"])
        }

        // 转换为 PNG 格式（统一格式，便于管理）
        guard let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "ImageStorageManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "无法转换图片格式"])
        }
        
        // 计算哈希值
        let hash = SHA256.hash(data: pngData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // 使用哈希值作为文件名
        let fileName = "\(hashString).png"
        let fileURL = storageDirectory.appendingPathComponent(fileName)
        
        // 如果文件已存在，直接返回（去重）
        if FileManager.default.fileExists(atPath: fileURL.path) {
            print("📸 图片已存在，跳过保存: \(fileName)")
        } else {
            // 保存图片
            try pngData.write(to: fileURL)
            print("✅ 图片已保存: \(fileName) (\(ByteCountFormatter.string(fromByteCount: Int64(pngData.count), countStyle: .file)))")
        }
        
        // 获取图片尺寸
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        
        return (path: fileURL.path, hash: hashString, width: width, height: height)
    }
    
    /// 删除图片文件
    func deleteImage(at path: String) {
        let fileURL = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: fileURL)
        print("🗑️  已删除图片: \(path)")
    }
    
    /// 清理所有图片
    func clearAllImages() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
        
        print("🗑️  已清理所有图片 (\(files.count) 个)")
    }
    
    /// 清理孤立的图片文件（数据库中没有引用的）
    func cleanOrphanedImages(referencedPaths: [String]) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        let referencedSet = Set(referencedPaths)
        var deletedCount = 0
        
        for file in files {
            if !referencedSet.contains(file.path) {
                try? FileManager.default.removeItem(at: file)
                deletedCount += 1
            }
        }
        
        if deletedCount > 0 {
            print("🗑️  已清理 \(deletedCount) 个孤立图片文件")
        }
    }
    
    /// 获取存储目录大小
    func getStorageSize() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for file in files {
            if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        
        return totalSize
    }
}

