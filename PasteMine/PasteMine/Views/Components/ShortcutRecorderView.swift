//
//  ShortcutRecorderView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/23.
//

import SwiftUI
import Carbon

/// 快捷键录制视图
struct ShortcutRecorderView: View {
    @Binding var shortcut: KeyboardShortcut
    @State private var isRecording = false
    @State private var currentDisplay = ""
    
    var body: some View {
        HStack {
            // 显示区域
            Text(isRecording ? (currentDisplay.isEmpty ? AppText.Common.pressShortcut : currentDisplay) : shortcut.displayString)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRecording ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onTapGesture {
                    startRecording()
                }

            // 录制/完成按钮
            Button(isRecording ? AppText.Common.finishRecording : AppText.Common.recordShortcut) {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
            .buttonStyle(.bordered)

            // 重置按钮
            if shortcut != .defaultShortcut {
                Button(AppText.Common.resetShortcut) {
                    shortcut = .defaultShortcut
                }
                .buttonStyle(.borderless)
            }
        }
        .onAppear {
            setupKeyMonitor()
        }
    }
    
    private func startRecording() {
        isRecording = true
        currentDisplay = ""
    }
    
    private func stopRecording() {
        isRecording = false
    }
    
    private func setupKeyMonitor() {
        // 监听本地键盘事件
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if isRecording {
                handleKeyEvent(event)
                return nil // 阻止事件传递
            }
            return event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // 只处理修饰键按下的情况
        if event.type == .keyDown {
            let keyCode = event.keyCode
            
            // 构建修饰键标志
            var modifiers: UInt32 = 0
            if modifierFlags.contains(.command) {
                modifiers |= UInt32(cmdKey)
            }
            if modifierFlags.contains(.shift) {
                modifiers |= UInt32(shiftKey)
            }
            if modifierFlags.contains(.option) {
                modifiers |= UInt32(optionKey)
            }
            if modifierFlags.contains(.control) {
                modifiers |= UInt32(controlKey)
            }
            
            // 至少需要一个修饰键
            guard modifiers != 0 else {
                return
            }
            
            // 创建新的快捷键
            let newShortcut = KeyboardShortcut(keyCode: keyCode, modifiers: modifiers)
            
            // 验证快捷键
            if newShortcut.isValid {
                currentDisplay = newShortcut.displayString
                shortcut = newShortcut
                
                // 自动停止录制
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    stopRecording()
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var shortcut = KeyboardShortcut.defaultShortcut

    VStack {
        ShortcutRecorderView(shortcut: $shortcut)
        Text(L10n.text("当前快捷键：\(shortcut.displayString)", "Current shortcut: \(shortcut.displayString)"))
    }
    .padding()
}

