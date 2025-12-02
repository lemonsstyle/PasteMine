//
//  AppPickerView.swift
//  PasteMine
//
//  Created for app selection with file picker
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AppPickerView: View {
    @Binding var apps: [IgnoredApp]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 显示已选择的应用列表
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if apps.isEmpty {
                        Text("列表为空")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(apps) { app in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    
                                    Text(app.bundleId)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        apps.removeAll { $0.bundleId == app.bundleId }
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("删除")
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                    }
                }
                .padding(4)
            }
            .frame(maxHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            
            // 添加按钮 - 打开文件选择器
            Button(action: {
                selectApp()
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("选择应用")
                }
                .font(.caption)
                .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func selectApp() {
        AppDelegate.shared?.windowManager?.pauseAutoHide()
        
        let panel = NSOpenPanel()
        panel.title = "选择要忽略的应用"
        panel.message = "请选择一个应用程序"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        panel.begin { response in
            // 延迟处理，确保文件选择器完全关闭
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                defer {
                    AppDelegate.shared?.windowManager?.resumeAutoHide()
                    AppDelegate.shared?.windowManager?.refocus()
                }
                
                if response == .OK, let url = panel.url {
                    guard let bundle = Bundle(url: url),
                          let bundleId = bundle.bundleIdentifier else {
                        NSSound.beep()
                        print("❌ 无法获取应用的 Bundle ID")
                        return
                    }
                    
                    // 获取显示名称（优先本地化名称）
                    var displayName = url.deletingPathExtension().lastPathComponent
                    
                    if let localizedName = bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
                        displayName = localizedName
                    } else if let localizedName = bundle.infoDictionary?["CFBundleDisplayName"] as? String {
                        displayName = localizedName
                    } else if let bundleName = bundle.localizedInfoDictionary?["CFBundleName"] as? String {
                        displayName = bundleName
                    } else if let bundleName = bundle.infoDictionary?["CFBundleName"] as? String {
                        displayName = bundleName
                    }
                    
                    let ignoredApp = IgnoredApp(bundleId: bundleId, displayName: displayName)
                    
                    // 检查是否已存在（通过 Bundle ID）
                    if !apps.contains(where: { $0.bundleId == bundleId }) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            apps.append(ignoredApp)
                        }
                        print("✅ 已添加忽略应用: \(displayName) (\(bundleId))")
                    } else {
                        // 已存在，播放提示音
                        NSSound.beep()
                        print("⚠️  应用已存在: \(displayName)")
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var testApps = [
        IgnoredApp(bundleId: "com.apple.Safari", displayName: "Safari"),
        IgnoredApp(bundleId: "com.tencent.xinWeChat", displayName: "微信")
    ]
    
    AppPickerView(
        apps: $testApps,
        title: "测试应用列表"
    )
    .padding()
    .frame(width: 320)
}
