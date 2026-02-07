//
//  PasteMineApp.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

@main
struct PasteMineApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // ⚠️ 对于 LSUIElement=true 的应用，不使用 Window 场景
        // 所有窗口由 AppDelegate 管理，避免 SwiftUI 生命周期问题
        Settings {
            EmptyView()
        }
    }
}
