//
//  HotKeyManager.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import Carbon
import AppKit

class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?
    
    /// 注册全局快捷键 (Cmd+Shift+V)
    /// 使用 Carbon API，不需要"输入监控"权限
    func register(callback: @escaping () -> Void) {
        self.callback = callback
        
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
        
        // 注册热键：Cmd + Shift + V
        // cmdKey = 256, shiftKey = 512
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_V) // V 键
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            print("✅ 全局快捷键已注册 (⌘⇧V) - 使用 Carbon API，无需输入监控权限")
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
        
        print("⏹️  全局快捷键已注销")
    }
    
    deinit {
        unregister()
    }
}

