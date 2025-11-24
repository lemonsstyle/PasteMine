# 🪟 PasteMine 窗口尺寸调整指南

本文档说明如何调整 PasteMine 应用中的窗口尺寸。

---

## 📐 窗口尺寸位置

### 1. **主窗口**（剪贴板历史列表）

**文件**：`PasteMine/PasteMine/Managers/WindowManager.swift`

**位置**：第 27 行

```swift
window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
    //                              ↑ 宽度     ↑ 高度
    styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
    backing: .buffered,
    defer: false
)
```

**当前值**：
- 宽度：`600` px
- 高度：`500` px

**调整方法**：
```swift
// 示例：改为 700 × 600
contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
```

---

### 2. **设置窗口**

**文件**：`PasteMine/PasteMine/Views/Settings/SettingsView.swift`

**位置**：第 127 行

```swift
.padding()
.frame(width: 500, height: 700)
//           ↑ 宽度     ↑ 高度
```

**当前值**：
- 宽度：`500` px
- 高度：`700` px

**调整方法**：
```swift
// 示例：改为 550 × 750
.frame(width: 550, height: 750)
```

---

## 🎨 其他尺寸设置

### 3. **图片缩略图大小**

**文件**：`PasteMine/PasteMine/Views/MainWindow/HistoryItemView.swift`

**位置**：第 40 行和第 47 行

```swift
.frame(width: 80, height: 80)
//           ↑ 宽度  ↑ 高度
```

**当前值**：`80 × 80` px

**调整方法**：
```swift
// 示例：改为 100 × 100
.frame(width: 100, height: 100)
```

---

## ⚙️ 调整步骤

### 方法 1：使用 Xcode（推荐）

1. **打开项目**
   ```bash
   open PasteMine/PasteMine.xcodeproj
   ```

2. **找到对应文件**
   - 使用 `⌘⇧O` 快速打开文件
   - 输入文件名搜索

3. **修改尺寸**
   - 找到对应的行号
   - 修改 `width` 和 `height` 的值

4. **编译运行**
   - 按 `⌘R` 运行
   - 或按 `⌘B` 只编译

### 方法 2：使用文本编辑器

1. **打开文件**
   ```bash
   # 主窗口
   code PasteMine/PasteMine/Managers/WindowManager.swift
   
   # 设置窗口
   code PasteMine/PasteMine/Views/Settings/SettingsView.swift
   ```

2. **修改尺寸**

3. **编译安装**
   ```bash
   cd PasteMine
   xcodebuild -scheme PasteMine -configuration Release build
   ../install.sh
   ```

---

## 📏 推荐尺寸

根据不同屏幕和使用场景，推荐以下尺寸：

### 小屏幕（13 寸 MacBook）
```swift
// 主窗口
NSRect(x: 0, y: 0, width: 550, height: 450)

// 设置窗口
.frame(width: 480, height: 650)
```

### 中等屏幕（15-16 寸 MacBook）
```swift
// 主窗口（当前默认）
NSRect(x: 0, y: 0, width: 600, height: 500)

// 设置窗口（当前默认）
.frame(width: 500, height: 700)
```

### 大屏幕（外接显示器）
```swift
// 主窗口
NSRect(x: 0, y: 0, width: 700, height: 600)

// 设置窗口
.frame(width: 550, height: 750)
```

---

## 💡 调整建议

### 宽度调整：
- **主窗口**：建议 500-800 px
  - 太窄：文本显示不全
  - 太宽：占用屏幕空间

- **设置窗口**：建议 450-600 px
  - 根据设置选项的宽度调整

### 高度调整：
- **主窗口**：建议 400-700 px
  - 取决于想显示多少条历史记录

- **设置窗口**：建议 600-800 px
  - 根据设置项数量调整
  - 确保所有选项都能显示

### 图片缩略图：
- 建议：60-120 px
- 太小：看不清图片内容
- 太大：占用列表空间

---

## 🔍 验证方法

修改后，测试以下场景：

1. ✅ **主窗口**
   - 显示 5-10 条记录不拥挤
   - 搜索栏、列表都完整显示
   - 窗口不超出屏幕边界

2. ✅ **设置窗口**
   - 所有设置项都能看到
   - 不需要滚动查看
   - "完成"按钮在底部可见

3. ✅ **图片缩略图**
   - 能清楚看到图片内容
   - 不影响文本显示
   - 列表行高合适

---

## 🚨 注意事项

1. **屏幕边界检测**
   - WindowManager 有智能定位逻辑
   - 窗口不会超出屏幕范围
   - 如果设置太大，可能被自动调整

2. **用户可调整**
   - 主窗口支持用户拖拽调整大小（`.resizable`）
   - 设置窗口是固定大小

3. **修改后需要**
   - 重新编译
   - 重新安装
   - 重启应用

---

## 📝 修改历史

| 日期 | 版本 | 主窗口 | 设置窗口 | 说明 |
|------|------|--------|----------|------|
| 2025-11-23 | v1.1.0 | 600×500 | 500×700 | 调整设置窗口高度 |
| 2025-11-22 | v1.0.1 | 600×500 | 480×600 | 初始版本 |

---

如有问题，请参考代码注释或联系开发者。

