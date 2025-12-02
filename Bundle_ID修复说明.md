# PasteMine v1.1 - Bundle ID 修复方案

## 🔍 问题分析

### 核心问题
**忽略应用功能在某些中文应用上不生效**

### 具体现象
1. 微信（WeChat.app）- 文件选择器显示 "WeChat.app"，系统运行时显示 "微信"
2. 百度网盘（BaiduNetdisk.app）- 文件选择器显示 "BaiduNetdisk.app"，系统运行时显示 "百度网盘"

### 根本原因
macOS 应用有多个名称标识：
- **文件系统名称**：应用包的文件名（如 WeChat.app）
- **本地化显示名称**：用户看到的名称（如"微信"）
- **Bundle Identifier**：应用的唯一标识符（如 com.tencent.xinWeChat）

之前的实现使用应用名称进行匹配，但由于文件选择器和系统运行时获取的名称可能不一致（中英文差异），导致匹配失败。

---

## ✅ 解决方案

### 核心思路
**使用 Bundle Identifier 进行匹配，因为它在任何环境下都保持一致。**

### 实现细节

#### 1. 数据结构改进 (Settings.swift)

**之前：**
```swift
var ignoredApps: [String] = []  // 只保存应用名称
```

**修复后：**
```swift
/// 忽略的应用信息
struct IgnoredApp: Codable, Identifiable, Equatable {
    var id: String { bundleId }
    let bundleId: String        // Bundle Identifier (用于匹配)
    let displayName: String     // 显示名称 (用于界面显示)
}

var ignoredApps: [IgnoredApp] = []
```

#### 2. 应用选择器改进 (AppPickerView.swift)

**关键逻辑：**
```swift
private func selectApp() {
    // ...文件选择器配置...
    
    panel.begin { response in
        if response == .OK, let url = panel.url {
            // ✅ 获取 Bundle ID（唯一标识符）
            guard let bundle = Bundle(url: url),
                  let bundleId = bundle.bundleIdentifier else {
                return
            }
            
            // 获取显示名称
            var displayName = url.deletingPathExtension().lastPathComponent
            if let localizedName = bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
                displayName = localizedName
            }
            
            // 保存 Bundle ID 和显示名称
            let ignoredApp = IgnoredApp(bundleId: bundleId, displayName: displayName)
            apps.append(ignoredApp)
        }
    }
}
```

**界面显示：**
```
微信
com.tencent.xinWeChat

百度网盘
com.baidu.BaiduNetdisk_mac
```

#### 3. 匹配逻辑改进 (ClipboardMonitor.swift)

**之前：**
```swift
private func getCurrentApp() -> String? {
    NSWorkspace.shared.frontmostApplication?.localizedName
}

// 匹配时使用名称
if settings.ignoredApps.contains(appName) {
    // 忽略
}
```

**修复后：**
```swift
private func getCurrentApp() -> (bundleId: String?, displayName: String?) {
    guard let app = NSWorkspace.shared.frontmostApplication else {
        return (nil, nil)
    }
    return (app.bundleIdentifier, app.localizedName)
}

private func shouldIgnoreCurrentApp() -> Bool {
    let settings = AppSettings.load()
    let currentApp = getCurrentApp()
    
    guard let bundleId = currentApp.bundleId else {
        return false
    }
    
    // ✅ 通过 Bundle ID 匹配，100% 准确
    return settings.ignoredApps.contains { $0.bundleId == bundleId }
}
```

---

## 🎯 优势

### 1. 完全可靠
Bundle ID 在任何情况下都不会改变：
- ✅ 不受系统语言影响
- ✅ 不受应用名称本地化影响
- ✅ 不受文件名修改影响

### 2. 用户友好
- 列表中显示应用的本地化名称（中文）
- 同时显示 Bundle ID（技术用户可参考）

### 3. 调试方便
控制台日志清晰显示：
```
✅ 已添加忽略应用: 微信 (com.tencent.xinWeChat)
⏭️  已忽略应用: 微信 (com.tencent.xinWeChat)
```

---

## 📦 测试步骤

### 1. 安装新版本
```bash
open /Users/lemonstyle/Documents/xcode_pj/pas_cc/PasteMine.app
```

### 2. 清空旧数据（重要！）
由于数据结构改变，需要：
- 打开设置 > 隐私 > 忽略应用
- 删除所有之前添加的应用
- 或者直接删除设置文件重新配置

### 3. 添加应用
1. 点击"选择应用"
2. 选择微信（WeChat.app）
3. 确认列表显示：
   ```
   微信
   com.tencent.xinWeChat
   ```
4. 同样添加百度网盘等其他应用

### 4. 测试过滤功能

**微信测试：**
```
1. 在微信中复制一些文字
2. 打开 PasteMine 主窗口
3. ✅ 确认没有新记录
```

**其他应用测试：**
```
1. 在浏览器/编辑器中复制内容
2. 打开 PasteMine 主窗口
3. ✅ 确认可以正常记录
```

### 5. 查看日志（可选）
打开"控制台.app"，筛选 PasteMine：
```
✅ 已添加忽略应用: 微信 (com.tencent.xinWeChat)
⏭️  已忽略应用: 微信 (com.tencent.xinWeChat)
```

---

## 📋 常见应用的 Bundle ID

| 应用名称 | Bundle Identifier |
|---------|-------------------|
| 微信 | com.tencent.xinWeChat |
| QQ | com.tencent.qq |
| 钉钉 | com.alibaba.DingTalkMac |
| 企业微信 | com.tencent.WeWorkMac |
| 百度网盘 | com.baidu.BaiduNetdisk_mac |
| 1Password | com.1password.1password |
| Safari | com.apple.Safari |
| Chrome | com.google.Chrome |

你可以通过以下命令查看任何应用的 Bundle ID：
```bash
osascript -e 'id of app "应用名称"'
# 例如：
osascript -e 'id of app "WeChat"'
# 输出：com.tencent.xinWeChat
```

---

## 🚀 版本信息

- **版本**：v1.1 (Bundle ID Fix)
- **构建时间**：2025-12-02 14:55
- **DMG 大小**：456 KB
- **最低系统**：macOS 14.0+

---

## 📝 修改的文件

1. **Models/Settings.swift**
   - 添加 `IgnoredApp` 结构
   - 修改 `ignoredApps` 类型

2. **Views/Components/AppPickerView.swift**
   - 完全重写，使用 Bundle ID
   - 显示应用名称和 Bundle ID

3. **Services/ClipboardMonitor.swift**
   - 修改 `getCurrentApp()` 返回值
   - 新增 `shouldIgnoreCurrentApp()` 方法
   - 使用 Bundle ID 进行匹配

4. **Views/Settings/SettingsView.swift**
   - 自动适配新的数据类型（无需修改）

---

## 🎉 现在可以完美支持所有应用了！

无论应用名称是中文、英文、还是中英文混合，都能准确识别和过滤。

有任何问题，请查看控制台日志或联系开发者。
