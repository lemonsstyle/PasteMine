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
            // Background
            if #available(macOS 14, *) {
                Color.clear
                    .background(.ultraThinMaterial)
            } else {
                Color(NSColor.windowBackgroundColor)
            }

            ScrollView {
                VStack(spacing: 0) {
                    // Header (only show for steps 1-3, not for welcome step 0)
                    if currentStep > 0 {
                        VStack(spacing: 6) {
                            Image(systemName: "hand.wave.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.blue)
                                .padding(.top, 16)

                            Text(AppText.Onboarding.title)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(AppText.Onboarding.welcomeSlogan)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 16)
                    }

                    // Steps
                    VStack(spacing: 20) {
                        if currentStep == 0 {
                            // Step 0: Welcome
                            WelcomeStepView(
                                onContinue: {
                                    withAnimation {
                                        currentStep = 1
                                    }
                                }
                            )
                        } else if currentStep == 1 {
                            // Step 1: notification permission
                            NotificationPermissionStepView(
                                isGranted: $notificationPermissionGranted,
                                primaryAction: {
                                    requestNotificationPermission()
                                },
                                secondaryAction: {
                                    withAnimation {
                                        currentStep = 2
                                    }
                                }
                            )
                        } else if currentStep == 2 {
                            // Step 2: accessibility permission
                            AccessibilityPermissionStepView(
                                isGranted: $accessibilityPermissionGranted,
                                primaryAction: {
                                    openAccessibilitySettings()
                                },
                                secondaryAction: {
                                    withAnimation {
                                        currentStep = 3
                                    }
                                }
                            )
                        } else {
                            // Step 3: completion
                            CompletionStepView(
                                notificationGranted: notificationPermissionGranted,
                                accessibilityGranted: accessibilityPermissionGranted,
                                onComplete: {
                                    completeOnboarding()
                                }
                            )
                        }
                    }
                    .frame(minHeight: 480)
                    .animation(.easeInOut, value: currentStep)

                    // Pager dots (4 dots now)
                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(currentStep == index ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 600)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: 600, height: 700)
        .onAppear {
            checkPermissions()
        }
    }

    private func requestNotificationPermission() {
        print("🔔 Requesting notification permission...")

        // Ensure app is active so the system sheet can appear
        NSApp.activate(ignoringOtherApps: true)

        // Small delay to ensure activation is done
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Check current status first
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                print("📊 Notification status: \(settings.authorizationStatus.rawValue)")

                if settings.authorizationStatus == .notDetermined {
                    // First-time request
                    print("🔔 First request, system dialog will appear...")

                    // Ensure activation again (LSUIElement app)
                    NSApp.activate(ignoringOtherApps: true)

                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        DispatchQueue.main.async {
                            if let error = error {
                                print("❌ Notification permission failed: \(error.localizedDescription)")
                            } else {
                                let result = granted ? "granted" : "denied"
                                print("✅ Notification permission: \(result)")
                            }
                            self.notificationPermissionGranted = granted
                            if granted {
                                // Go next
                                withAnimation {
                                    self.currentStep = 2
                                }
                            }
                        }
                    }
                } else if settings.authorizationStatus == .authorized {
                    // Already granted
                    DispatchQueue.main.async {
                        print("✅ Notification already granted")
                        self.notificationPermissionGranted = true
                        withAnimation {
                            self.currentStep = 2
                        }
                    }
                } else if settings.authorizationStatus == .denied {
                    // Denied: guide to system settings
                    DispatchQueue.main.async {
                        print("⚠️ Notification permission denied, enable manually")
                        self.notificationPermissionGranted = false
                        // Open system settings
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
    }

    private func openAccessibilitySettings() {
        // Open system settings accessibility page
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)

        // Start checking permission state
        startCheckingAccessibilityPermission()
    }

    private func startCheckingAccessibilityPermission() {
        // Check every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let granted = NSApplication.shared.isAccessibilityPermissionGranted()

            if granted != accessibilityPermissionGranted {
                DispatchQueue.main.async {
                    accessibilityPermissionGranted = granted

                    if granted {
                        // Granted: go next
                        withAnimation {
                            currentStep = 3
                        }
                        timer.invalidate()
                    }
                }
            }

            // Stop if step changed
            if currentStep != 2 {
                timer.invalidate()
            }
        }
    }

    private func checkPermissions() {
        // Check notification permission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }

        // Check accessibility
        accessibilityPermissionGranted = NSApplication.shared.isAccessibilityPermissionGranted()
    }

    private func completeOnboarding() {
        print("🎉 Completing onboarding...")

        // Mark as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // Refresh notification status
        NotificationService.shared.refreshAuthorizationStatus()

        print("✅ Onboarding done, menu bar icon ready")
        print("💡 Tip: Click the menu bar icon or press ⌘⇧V to open history")

        // Close onboarding window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let window = NSApp.windows.first(where: { $0.title == AppText.Onboarding.title }) {
                window.close()
                print("✅ Onboarding window closed")
            }

            // Ensure app stays active
            NSApp.activate(ignoringOtherApps: true)

            // Extra safety check
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !NSApp.isActive {
                    print("⚠️ App not active, re-activating")
                    NSApp.activate(ignoringOtherApps: true)
                }
                print("✅ App state check done")
            }
        }
    }
}

// MARK: - Welcome Step View (NEW)

struct WelcomeStepView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // App Icon
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .padding(.top, 20)

            // Title & Slogan
            VStack(spacing: 6) {
                Text(AppText.Onboarding.welcomeTitle)
                    .font(.title)
                    .fontWeight(.bold)

                Text(AppText.Onboarding.welcomeSlogan)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 4)

            // Feature Cards
            VStack(spacing: 10) {
                FeatureCard(
                    icon: "tray.full.fill",
                    iconColor: .blue,
                    title: AppText.Onboarding.feature1Title,
                    description: AppText.Onboarding.feature1Desc
                )

                FeatureCard(
                    icon: "bolt.fill",
                    iconColor: .orange,
                    title: AppText.Onboarding.feature2Title,
                    description: AppText.Onboarding.feature2Desc
                )

                FeatureCard(
                    icon: "magnifyingglass.circle.fill",
                    iconColor: .green,
                    title: AppText.Onboarding.feature3Title,
                    description: AppText.Onboarding.feature3Desc
                )
            }
            .padding(.horizontal, 16)

            Spacer()
                .frame(height: 16)

            // CTA Button
            Button(action: onContinue) {
                HStack(spacing: 8) {
                    Text(AppText.Onboarding.startSetup)
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Feature Card (NEW)

struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background {
            if #available(macOS 14, *) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.regularMaterial)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            }
        }
    }
}

// MARK: - Notification Permission Step (ENHANCED)

struct NotificationPermissionStepView: View {
    @Binding var isGranted: Bool
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    @State private var isDenied = false

    var body: some View {
        VStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "bell.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
            }
            .padding(.top, 8)

            // Title
            VStack(spacing: 5) {
                Text(AppText.Onboarding.enableNotifications)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(AppText.Onboarding.notificationDesc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Benefits (ENHANCED - 4 benefits)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(AppText.Onboarding.notificationBenefitsTitle)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    NotificationBenefitRow(text: AppText.Onboarding.benefit1)
                    NotificationBenefitRow(text: AppText.Onboarding.benefit2)
                    NotificationBenefitRow(text: AppText.Onboarding.benefit3)
                    NotificationBenefitRow(text: AppText.Onboarding.benefit4)
                }

                // Non-intrusive assurance (NEW)
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(AppText.Onboarding.nonIntrusive)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 3)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if #available(macOS 14, *) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.05))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)

            // Status
            if isGranted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(AppText.PermissionStatus.granted)
                        .foregroundStyle(.green)
                        .fontWeight(.medium)
                }
                .padding(.top, 3)
            } else if isDenied {
                VStack(spacing: 5) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text(AppText.Onboarding.permissionDenied)
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)
                    }
                    Text(AppText.Onboarding.enableInSettings)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 3)
            }

            Spacer()
                .frame(height: 12)

            // Buttons
            VStack(spacing: 10) {
                if !isGranted {
                    Button(action: {
                        if isDenied {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                                NSWorkspace.shared.open(url)
                            }
                        } else {
                            primaryAction()
                        }
                    }) {
                        Text(isDenied ? L10n.text("打开系统设置", "Open System Settings") : AppText.Onboarding.grantPermission)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: secondaryAction) {
                    Text(isGranted ? AppText.Onboarding.nextStep : AppText.Onboarding.maybeLater)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(isGranted ? Color.accentColor : Color.clear)
                        .foregroundColor(isGranted ? .white : .primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    isDenied = settings.authorizationStatus == .denied
                    isGranted = settings.authorizationStatus == .authorized
                }
            }
        }
    }
}

// MARK: - Notification Benefit Row (NEW)

struct NotificationBenefitRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("✓")
                .font(.caption)
                .foregroundStyle(.green)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Accessibility Permission Step (ENHANCED)

struct AccessibilityPermissionStepView: View {
    @Binding var isGranted: Bool
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            }
            .padding(.top, 8)

            // Title
            VStack(spacing: 5) {
                Text(AppText.Onboarding.enableAccessibility)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(AppText.Onboarding.unlockCoreFeatures)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Comparison Cards (NEW)
            HStack(spacing: 10) {
                // Without Permission
                VStack(spacing: 7) {
                    Image(systemName: "xmark.circle")
                        .font(.title3)
                        .foregroundStyle(.orange)

                    Text(AppText.Onboarding.withoutPermission)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text(AppText.Onboarding.withoutDesc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background {
                    if #available(macOS 14, *) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.regularMaterial)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    }
                }

                // With Permission
                VStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)

                    Text(AppText.Onboarding.withPermission)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(AppText.Onboarding.withDesc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.1))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
                )
            }
            .padding(.horizontal, 20)

            // Simplified Steps (3 instead of 5)
            VStack(alignment: .leading, spacing: 8) {
                Text(AppText.Onboarding.setupSteps)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 6) {
                    SimpleStepRow(number: "1", text: AppText.Onboarding.step1Simple)
                    SimpleStepRow(number: "2", text: AppText.Onboarding.step2Simple)
                    SimpleStepRow(number: "3", text: AppText.Onboarding.step3Simple)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if #available(macOS 14, *) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.regularMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                }
            }
            .padding(.horizontal, 20)

            // Security Promise (NEW)
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text(AppText.Onboarding.securityPromise)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)

            // Status
            if isGranted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(AppText.PermissionStatus.granted)
                        .foregroundStyle(.green)
                        .fontWeight(.medium)
                }
                .padding(.top, 3)
            }

            Spacer()
                .frame(height: 10)

            // Buttons
            VStack(spacing: 10) {
                if !isGranted {
                    Button(action: primaryAction) {
                        Text(L10n.text("打开系统设置", "Open System Settings"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: secondaryAction) {
                    Text(isGranted ? AppText.Onboarding.nextStep : AppText.Onboarding.maybeLater)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(isGranted ? Color.accentColor : Color.clear)
                        .foregroundColor(isGranted ? .white : .primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Simple Step Row (NEW - replaces complex 5-step StepRow)

struct SimpleStepRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.accentColor))

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

// MARK: - Completion Step (ENHANCED)

struct CompletionStepView: View {
    let notificationGranted: Bool
    let accessibilityGranted: Bool
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            }
            .padding(.top, 8)

            // Title
            VStack(spacing: 5) {
                Text(AppText.Onboarding.setupComplete)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(AppText.Onboarding.nowReady)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Permission summary
            VStack(spacing: 8) {
                PermissionStatusRow(
                    icon: "bell.fill",
                    title: AppText.Onboarding.notificationLabel,
                    isGranted: notificationGranted
                )

                PermissionStatusRow(
                    icon: "hand.point.up.left.fill",
                    title: AppText.Onboarding.accessibilityLabel,
                    isGranted: accessibilityGranted
                )
            }
            .padding(12)
            .background {
                if #available(macOS 14, *) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.regularMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                }
            }
            .padding(.horizontal, 20)

            // Shortcut Keys Card (NEW)
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "keyboard.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(AppText.Onboarding.shortcutLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 4) {
                    KeyCapView(symbol: "⌘")
                    Text("+")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    KeyCapView(symbol: "⇧")
                    Text("+")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    KeyCapView(symbol: "V")
                }

                Text(AppText.Onboarding.shortcutDesc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background {
                if #available(macOS 14, *) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.05))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)

            // Quick Start Guide (NEW)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(AppText.Onboarding.quickStartLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    QuickTipRow(text: AppText.Onboarding.quickTip1)
                    QuickTipRow(text: AppText.Onboarding.quickTip2)
                    QuickTipRow(text: AppText.Onboarding.quickTip3)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if #available(macOS 14, *) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.05))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)

            // Missing permissions hint
            if !notificationGranted || !accessibilityGranted {
                Text(AppText.Onboarding.missingPermissions)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 3)
            }

            Spacer()
                .frame(height: 10)

            // Dual CTAs (NEW)
            VStack(spacing: 10) {
                Button(action: onComplete) {
                    Text(AppText.Onboarding.tryNow)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: onComplete) {
                    Text(AppText.Onboarding.startLater)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Key Cap View (NEW)

struct KeyCapView: View {
    let symbol: String

    var body: some View {
        Text(symbol)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.primary)
            .frame(width: 26, height: 26)
            .background {
                if #available(macOS 14, *) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.regularMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(NSColor.controlBackgroundColor))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Quick Tip Row (NEW)

struct QuickTipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.caption)
                .foregroundStyle(.orange)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Permission Status Row (Existing)

struct PermissionStatusRow: View {
    let icon: String
    let title: String
    let isGranted: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(isGranted ? .green : .orange)
                .frame(width: 24)

            Text(title)
                .font(.callout)

            Spacer()

            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isGranted ? .green : .orange)

            Text(isGranted ? AppText.PermissionStatus.granted : AppText.PermissionStatus.notGranted)
                .font(.caption2)
                .foregroundStyle(isGranted ? .green : .orange)
        }
    }
}

#Preview {
    OnboardingView()
}
