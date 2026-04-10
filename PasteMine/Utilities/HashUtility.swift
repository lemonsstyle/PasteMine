//
//  HashUtility.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import Foundation
import CryptoKit

struct HashUtility {
    /// 计算字符串的 SHA-256 哈希值
    static func sha256(_ string: String) -> String {
        let data = Data(string.utf8)
        return sha256Data(data)
    }
    
    /// 计算 Data 的 SHA-256 哈希值
    static func sha256Data(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

