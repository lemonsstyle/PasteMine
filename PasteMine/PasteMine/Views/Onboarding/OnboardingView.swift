//
//  OnboardingView.swift
//  PasteMine
//
//  Created for first launch experience
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var accessibilityGranted = false
    @State private var notificationGranted = false

    private let steps = [
        OnboardingStep(
            icon: "hand.raised.fill",
            title: "欢迎使用 PasteMine",
            description: "PasteMine 是一个强大的剪贴板历史管理工具\n让我们进行简单的设置"
        ),
        OnboardingStep(
            icon: "checkmark.shield.fill",
            title: "辅助功能权限",
            description: "需要此权限来监听剪贴板变化\n和实现自动粘贴功能"
        ),
        OnboardingStep(
            icon: "bell.fill",
            title: "通知权限",
            description: "允许通知以便在复制内容时\n向您显示提醒"
        ),
        OnboardingStep(
            icon: "keyboard.fill",
            title: "快捷键说明",
            description: "按 ⌘⇧V 打开剪贴板历史窗口\n选择内容后按回车即可粘贴"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 进度指示器
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)

            Spacer()

            // 当前步骤内容
            VStack(spacing: 24) {
                Image(systemName: steps[currentStep].icon)
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)

                Text(steps[currentStep].title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(steps[currentStep].description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)

                // 步骤特定的按钮
                stepActionButton()
                    .padding(.top, 12)
            }

            Spacer()

            // 底部导航按钮
            HStack {
                if currentStep > 0 {
                    Button("上一步") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentStep < steps.count - 1 {
                    Button("下一步") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceedToNext())
                } else {
                    Button("开始使用") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .frame(width: 500, height: 450)
        .background {
            if #available(macOS 14, *) {
                Color.clear
                    .background(.ultraThinMaterial)
            } else {
                Color(NSColor.windowBackgroundColor)
            }
        }
    }

    @ViewBuilder
    private func stepActionButton() -> some View {
        switch currentStep {
        case 1: // 辅助功能权限
            VStack(spacing: 12) {
                Button(action: requestAccessibilityPermission) {
                    HStack {
                        Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "hand.point.up.left.fill")
                        Text(accessibilityGranted ? "权限已授予" : "授予辅助功能权限")
                    }
                    .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .disabled(accessibilityGranted)
                .tint(accessibilityGranted ? .green : .accentColor)

                if !accessibilityGranted {
                    Text("点击按钮后将打开系统设置")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

        case 2: // 通知权限
            VStack(spacing: 12) {
                Button(action: requestNotificationPermission) {
                    HStack {
                        Image(systemName: notificationGranted ? "checkmark.circle.fill" : "bell.badge.fill")
                        Text(notificationGranted ? "权限已授予" : "授予通知权限")
                    }
                    .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .disabled(notificationGranted)
                .tint(notificationGranted ? .green : .accentColor)

                if !notificationGranted {
                    Text("将弹出系统通知权限请求")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

        default:
            EmptyView()
        }
    }

    private func canProceedToNext() -> Bool {
        switch currentStep {
        case 1: return accessibilityGranted
        case 2: return notificationGranted
        default: return true
        }
    }

    private func requestAccessibilityPermission() {
        NSApplication.shared.requestAccessibilityPermission()

        // 检查权限状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkAccessibilityStatus()
        }

        // 持续检查直到授予权限
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            checkAccessibilityStatus()
            if accessibilityGranted {
                timer.invalidate()
            }
        }
    }

    private func checkAccessibilityStatus() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        withAnimation {
            accessibilityGranted = accessEnabled
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                withAnimation {
                    notificationGranted = granted
                }

                if granted {
                    print("✅ 通知权限已授予")
                } else if let error = error {
                    print("❌ 通知权限请求失败: \(error)")
                } else {
                    print("⚠️ 通知权限被拒绝")
                }
            }
        }
    }

    private func completeOnboarding() {
        // 标记引导完成
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}

struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
}

#Preview {
    OnboardingView()
}
