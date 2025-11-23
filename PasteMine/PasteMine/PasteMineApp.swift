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
        Settings {
            EmptyView() // 不使用默认窗口，由 WindowManager 管理
        }
    }
}
