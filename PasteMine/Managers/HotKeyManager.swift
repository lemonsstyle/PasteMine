//
//  HotKeyManager.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import Carbon
import AppKit

// 通知名称
extension Notification.Name {
    static let shortcutDidChange = Notification.Name("shortcutDidChange")
}

class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?
    
    init() {
        // 监听快捷键设置变更
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shortcutSettingsDidChange),
            name: .shortcutDidChange,
            object: nil
        )
    }
    
    /// 注册全局快捷键（使用设置中的快捷键）
    /// 使用 Carbon API，不需要"输入监控"权限
    func register(callback: @escaping () -> Void) {
        self.callback = callback
        
        // 从设置读取快捷键
        let settings = AppSettings.load()
        let shortcut = settings.globalShortcut
        
        // 先注销旧的快捷键
        unregister()
        
        // 定义快捷键 ID
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = 0x50535447 // "PSTM" 的 FourCharCode
        hotKeyID.id = 1
        
        // 定义事件类型
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        // 创建事件处理器
        let eventHandlerCallback: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else {
                return OSStatus(eventNotHandledErr)
            }
            
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            
            // 在主线程执行回调
            DispatchQueue.main.async {
                manager.callback?()
            }
            
            return noErr
        }
        
        // 注册事件处理器
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            eventHandlerCallback,
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
        
        // 注册热键（使用设置中的键码和修饰键）
        let status = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            print("✅ 全局快捷键已注册: \(shortcut.displayString) - 使用 Carbon API")
        } else {
            print("⚠️  快捷键注册失败: \(status)")
        }
    }
    
    /// 注销快捷键
    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    /// 快捷键设置变更时重新注册
    @objc private func shortcutSettingsDidChange() {
        print("🔄 快捷键设置已变更，重新注册...")
        if let callback = callback {
            register(callback: callback)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        unregister()
    }
}

