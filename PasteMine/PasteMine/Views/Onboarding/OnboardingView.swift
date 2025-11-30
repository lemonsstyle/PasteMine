//
//  OnboardingView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/30.
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var notificationPermissionGranted = false
    @State private var accessibilityPermissionGranted = false

    var body: some View {
        ZStack {
            // 背景
            if #available(macOS 14, *) {
                Color.clear
                    .background(.ultraThinMaterial)
            } else {
                Color(NSColor.windowBackgroundColor)
            }

            VStack(spacing: 0) {
                // 标题区域
                VStack(spacing: 8) {
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                        .padding(.top, 32)

                    Text("欢迎使用 PasteMine")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("一款优雅的剪贴板历史管理工具")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 32)

                // 步骤内容
                VStack(spacing: 20) {
                    if currentStep == 0 {
                        // 步骤 1: 通知权限
                        PermissionStepView(
                            icon: "bell.fill",
                            iconColor: .blue,
                            title: "开启通知",
                            description: "接收剪贴板复制和粘贴提醒",
                            isGranted: $notificationPermissionGranted,
                            primaryButtonTitle: "授予权限",
                            primaryAction: {
                                requestNotificationPermission()
                            },
                            secondaryButtonTitle: "稍后设置",
                            secondaryAction: {
                                currentStep = 1
                            }
                        )
                    } else if currentStep == 1 {
                        // 步骤 2: 辅助功能权限
                        PermissionStepView(
                            icon: "hand.point.up.left.fill",
                            iconColor: .green,
                            title: "开启辅助功能",
                            description: "允许 PasteMine 实现自动粘贴功能",
                            isGranted: $accessibilityPermissionGranted,
                            primaryButtonTitle: "打开系统设置",
                            primaryAction: {
                                openAccessibilitySettings()
                            },
                            secondaryButtonTitle: "稍后设置",
                            secondaryAction: {
                                currentStep = 2
                            }
                        )
                    } else {
                        // 步骤 3: 完成
                        CompletionStepView(
                            notificationGranted: notificationPermissionGranted,
                            accessibilityGranted: accessibilityPermissionGranted,
                            onComplete: {
                                completeOnboarding()
                            }
                        )
                    }
                }
                .frame(height: 400)
                .animation(.easeInOut, value: currentStep)

                // 底部指示器
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(currentStep == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .frame(width: 500, height: 480)
        .onAppear {
            checkPermissions()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                notificationPermissionGranted = granted
                if granted {
                    // 自动进入下一步
                    withAnimation {
                        currentStep = 1
                    }
                }
            }
        }
    }

    private func openAccessibilitySettings() {
        // 打开系统设置的辅助功能页面
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)

        // 开始检查权限状态
        startCheckingAccessibilityPermission()
    }

    private func startCheckingAccessibilityPermission() {
        // 每秒检查一次权限状态
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let granted = NSApplication.shared.isAccessibilityPermissionGranted()

            if granted != accessibilityPermissionGranted {
                DispatchQueue.main.async {
                    accessibilityPermissionGranted = granted

                    if granted {
                        // 权限已授予，自动进入下一步
                        withAnimation {
                            currentStep = 2
                        }
                        timer.invalidate()
                    }
                }
            }

            // 如果已经离开这个步骤，停止检查
            if currentStep != 1 {
                timer.invalidate()
            }
        }
    }

    private func checkPermissions() {
        // 检查通知权限
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }

        // 检查辅助功能权限
        accessibilityPermissionGranted = NSApplication.shared.isAccessibilityPermissionGranted()
    }

    private func completeOnboarding() {
        // 标记已完成引导
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // 关闭引导窗口
        if let window = NSApp.windows.first(where: { $0.title == "欢迎使用 PasteMine" }) {
            window.close()
        }
    }
}

// 权限步骤视图
struct PermissionStepView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    @Binding var isGranted: Bool
    let primaryButtonTitle: String
    let primaryAction: () -> Void
    let secondaryButtonTitle: String
    let secondaryAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(iconColor)
            }

            // 文本
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
            }

            // 状态指示
            if isGranted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("已授权")
                        .foregroundStyle(.green)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
            }

            Spacer()

            // 按钮
            VStack(spacing: 12) {
                if !isGranted {
                    Button(action: primaryAction) {
                        Text(primaryButtonTitle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }

                Button(action: secondaryAction) {
                    Text(isGranted ? "下一步" : secondaryButtonTitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isGranted ? Color.accentColor : Color.clear)
                        .foregroundColor(isGranted ? .white : .primary)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 48)
        }
    }
}

// 完成步骤视图
struct CompletionStepView: View {
    let notificationGranted: Bool
    let accessibilityGranted: Bool
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 成功图标
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
            }

            // 标题
            VStack(spacing: 8) {
                Text("设置完成！")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("您已准备好使用 PasteMine")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            // 权限状态总结
            VStack(spacing: 12) {
                PermissionStatusRow(
                    icon: "bell.fill",
                    title: "通知权限",
                    isGranted: notificationGranted
                )

                PermissionStatusRow(
                    icon: "hand.point.up.left.fill",
                    title: "辅助功能权限",
                    isGranted: accessibilityGranted
                )
            }
            .padding()
            .background {
                if #available(macOS 14, *) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                }
            }
            .padding(.horizontal, 48)
            .padding(.top, 16)

            if !notificationGranted || !accessibilityGranted {
                Text("您可以稍后在系统设置中开启缺失的权限")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }

            Spacer()

            // 完成按钮
            Button(action: onComplete) {
                Text("开始使用")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 48)
        }
    }
}

// 权限状态行
struct PermissionStatusRow: View {
    let icon: String
    let title: String
    let isGranted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isGranted ? .green : .orange)
                .frame(width: 28)

            Text(title)
                .font(.body)

            Spacer()

            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isGranted ? .green : .orange)

            Text(isGranted ? "已授权" : "未授权")
                .font(.caption)
                .foregroundStyle(isGranted ? .green : .orange)
        }
    }
}

#Preview {
    OnboardingView()
}
