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
    
    /// 保存图片原始数据并返回文件路径（保持原画质）
    /// - Parameters:
    ///   - data: 图片的原始二进制数据
    ///   - type: 图片的原始格式类型（如 .png, .tiff, .pdf）
    /// - Returns: (路径, 哈希值, 宽度, 高度, 格式)
    func saveImageRawData(_ data: Data, type: NSPasteboard.PasteboardType) throws -> (path: String, hash: String, width: Int, height: Int, format: String) {
        // 检查图片大小（如果启用了忽略大图片功能）
        let settings = AppSettings.load()
        if settings.ignoreLargeImages {
            let maxSize = Int64(AppSettings.largeImageThreshold) * 1024 * 1024  // 20MB
            if Int64(data.count) > maxSize {
                throw NSError(domain: "ImageStorageManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "图片大小超过 20MB，已跳过"])
            }
        }

        // 计算哈希值
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

        // 确定文件扩展名（保持原始格式）
        let fileExtension: String
        let formatString: String
        switch type {
        case .png:
            fileExtension = "png"
            formatString = "png"
        case .tiff:
            fileExtension = "tiff"
            formatString = "tiff"
        case .pdf:
            fileExtension = "pdf"
            formatString = "pdf"
        default:
            // 默认使用 png
            fileExtension = "png"
            formatString = "png"
        }

        // 使用哈希值作为文件名
        let fileName = "\(hashString).\(fileExtension)"
        let fileURL = storageDirectory.appendingPathComponent(fileName)

        // 获取图片尺寸（用于显示）
        var width = 0
        var height = 0
        if let image = NSImage(data: data),
           let representation = image.representations.first {
            // 使用实际像素尺寸，而非 points
            width = representation.pixelsWide
            height = representation.pixelsHigh
        }

        // 如果文件已存在，直接返回（去重）
        if FileManager.default.fileExists(atPath: fileURL.path) {
            print("📸 图片已存在，跳过保存: \(fileName)")
        } else {
            // 保存原始数据（无损）
            try data.write(to: fileURL)
            print("✅ 图片已保存（原画质）: \(fileName) (\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)))")
        }

        return (path: fileURL.path, hash: hashString, width: width, height: height, format: formatString)
    }

    /// 保存图片并返回文件路径（兼容旧接口，已弃用）
    @available(*, deprecated, message: "使用 saveImageRawData(_:type:) 保持原画质")
    func saveImage(_ image: NSImage) throws -> (path: String, hash: String, width: Int, height: Int) {
        // 获取图片的 TIFF 表示
        guard let tiffData = image.tiffRepresentation else {
            throw NSError(domain: "ImageStorageManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法获取图片数据"])
        }

        let result = try saveImageRawData(tiffData, type: .tiff)
        return (path: result.path, hash: result.hash, width: result.width, height: result.height)
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

