# PasteMine 项目架构文档

## 📋 项目概述

**PasteMine** 是一个 macOS 剪贴板历史管理工具，采用 SwiftUI 开发，提供优雅的用户界面和强大的剪贴板管理功能。

### 核心功能
- ✂️ 实时监控剪贴板内容（文本 + 图片）
- 💾 持久化存储剪贴板历史记录
- 🔍 快速搜索历史记录
- ⌨️ 全局快捷键呼出（默认 ⌘⇧V）
- 📋 一键粘贴历史内容
- 🔔 复制/粘贴通知提示
- 🔊 可选音效反馈
- 🚀 开机自启动支持
- 🎨 Liquid Glass 毛玻璃设计风格

---

## 🏗️ 项目结构

```
PasteMine/
├── App/                          # 应用程序入口
│   └── AppDelegate.swift         # 应用委托，负责初始化核心服务
│
├── Models/                       # 数据模型
│   ├── ClipboardItem.swift       # 剪贴板项（Core Data 实体）
│   ├── Settings.swift            # 应用设置模型
│   └── KeyboardShortcut.swift    # 快捷键模型
│
├── Services/                     # 核心服务层
│   ├── ClipboardMonitor.swift    # 剪贴板监控服务
│   ├── DatabaseService.swift     # 数据库服务（Core Data）
│   ├── PasteService.swift        # 粘贴服务
│   ├── NotificationService.swift # 通知服务
│   ├── SoundService.swift        # 音效服务
│   └── LaunchAtLoginService.swift# 开机自启动服务
│
├── Managers/                     # 管理器层
│   ├── WindowManager.swift       # 窗口管理器
│   └── HotKeyManager.swift       # 全局快捷键管理器
│
├── Views/                        # 视图层
│   ├── MainWindow/               # 主窗口视图
│   │   ├── HistoryListView.swift # 历史记录列表
│   │   ├── HistoryItemView.swift # 历史记录项
│   │   └── SearchBarView.swift   # 搜索栏
│   ├── Settings/                 # 设置视图
│   │   └── SettingsView.swift    # 设置页面
│   ├── Components/               # 可复用组件
│   │   ├── EmptyStateView.swift  # 空状态视图
│   │   └── ShortcutRecorderView.swift # 快捷键录制器
│   └── ContentView.swift         # 主内容视图
│
├── Utilities/                    # 工具类
│   ├── ImageStorageManager.swift # 图片存储管理器
│   ├── HashUtility.swift         # 哈希工具（SHA256）
│   └── Extensions.swift          # 扩展方法
│
├── Extensions/                   # 系统扩展
│   └── ColorExtensions.swift     # 颜色扩展
│
├── Resources/                    # 资源文件
│   └── Sounds/                   # 音效文件
│       ├── 1.wav - 6.wav        # 音效文件
│
└── PasteMine.xcdatamodeld/       # Core Data 数据模型
    └── PasteMine.xcdatamodel     # 数据模型定义
```

---

## 🔄 核心工作原理

### 1. 应用启动流程

```
PasteMineApp.swift (入口)
    ↓
AppDelegate.swift (初始化)
    ↓
┌─────────────────────────────────┐
│ 1. 初始化 DatabaseService       │
│ 2. 初始化 ClipboardMonitor      │
│ 3. 初始化 WindowManager         │
│ 4. 初始化 HotKeyManager         │
│ 5. 初始化 NotificationService   │
│ 6. 初始化 SoundService          │
│ 7. 设置开机自启动（如果启用）    │
└─────────────────────────────────┘
    ↓
启动剪贴板监控
```

### 2. 剪贴板监控机制

**ClipboardMonitor.swift** 是核心监控服务：

```swift
启动监控（每 0.5 秒检查一次）
    ↓
检测到剪贴板变化
    ↓
┌─────────────────┐
│ 1. 检查是否是粘贴操作 │ → 是 → 跳过（防止重复）
│ 2. 优先检查图片      │
│ 3. 其次检查文本      │
└─────────────────┘
    ↓
计算内容 SHA256 哈希
    ↓
与上次内容对比 → 相同 → 跳过
    ↓ 不同
保存到数据库
    ↓
发送通知 + 播放音效
```

**关键特性：**
- 去重机制：使用 SHA256 哈希值判断内容是否重复
- 防重复通知：检测粘贴操作，避免粘贴时触发复制通知
- 获取来源应用：记录复制内容的来源应用

### 3. 数据存储架构

#### 文本存储
- 直接存储在 Core Data 数据库中
- 字段：`content`（文本内容）

#### 图片存储（双层存储）

```
图片复制
    ↓
ImageStorageManager.saveImage()
    ↓
┌──────────────────────────────┐
│ 1. 获取图片 TIFF 数据         │
│ 2. 转换为 PNG 格式           │
│ 3. 计算 SHA256 哈希          │
│ 4. 保存到文件系统            │
│    ~/Library/Application     │
│    Support/PasteMine/images/ │
└──────────────────────────────┘
    ↓
Core Data 存储
    ↓
┌──────────────────────────────┐
│ - imagePath: 文件路径         │
│ - contentHash: SHA256 哈希    │
│ - imageWidth: 图片宽度        │
│ - imageHeight: 图片高度       │
└──────────────────────────────┘
```

**图片存储特点：**
- 使用 SHA256 哈希去重（相同图片只保存一次）
- PNG 格式统一管理
- 支持大小限制（5MB/10MB/20MB 可选）
- 自动清理孤立图片文件

### 4. 粘贴流程

**用户操作：** 点击历史记录项或按 Enter

```
PasteService.paste(item)
    ↓
┌────────────────────────────┐
│ 1. 设置 isPasting 标记     │
│ 2. 清空剪贴板             │
│ 3. 写入内容到剪贴板        │
│    - 文本：setString()    │
│    - 图片：writeObjects() │
└────────────────────────────┘
    ↓
隐藏窗口（0.15s 延迟）
    ↓
激活之前的应用（0.1s 延迟）
    ↓
模拟 Cmd+V 按键
    ↓
发送粘贴通知
    ↓
清除 isPasting 标记（0.6s 延迟）
```

**关键技术：**
- 使用 CGEvent 模拟键盘事件（Cmd+V）
- 需要辅助功能权限（Accessibility Permission）
- 通过 `isPasting` 标记防止触发重复的复制通知

### 5. 全局快捷键机制

**HotKeyManager.swift** 实现：

```swift
注册全局快捷键（默认 ⌘⇧V）
    ↓
使用 Carbon HotKey API
    ↓
监听快捷键事件
    ↓
触发 → WindowManager.toggle()
    ↓
┌─────────────────┐
│ 窗口隐藏 → 显示  │
│ 窗口显示 → 隐藏  │
└─────────────────┘
```

**支持的修饰键：**
- ⌘ Command
- ⇧ Shift
- ⌥ Option
- ⌃ Control

### 6. 窗口管理

**WindowManager.swift** 管理主窗口：

```swift
创建无边框浮动窗口
    ↓
┌──────────────────────────┐
│ 特性：                   │
│ - 无标题栏               │
│ - 毛玻璃效果             │
│ - 居中显示               │
│ - 失去焦点自动隐藏       │
│ - 记录上一个活跃应用     │
└──────────────────────────┘
```

---

## 📊 数据流图

### 复制流程
```
用户复制内容
    ↓
系统剪贴板变化
    ↓
ClipboardMonitor 检测
    ↓
┌─────────────────┐
│ 文本 → 直接保存 │
│ 图片 → 文件保存 │
└─────────────────┘
    ↓
DatabaseService.insert()
    ↓
Core Data 持久化
    ↓
通知 + 音效反馈
```

### 搜索流程
```
用户输入搜索关键词
    ↓
HistoryListView 过滤
    ↓
┌──────────────────────────┐
│ 实时过滤 Core Data 结果  │
│ - 文本：模糊匹配 content │
│ - 排序：按时间倒序       │
└──────────────────────────┘
    ↓
更新视图显示
```

### 删除流程
```
用户点击删除
    ↓
DatabaseService.delete()
    ↓
┌─────────────────────┐
│ 1. 删除 Core Data 记录│
│ 2. 删除图片文件      │
│    （如果是图片类型） │
└─────────────────────┘
    ↓
立即关闭窗口
    ↓
后台静默处理删除
```

---

## 🎨 设计模式

### 1. 单例模式（Singleton）
所有核心服务均采用单例模式：
- `DatabaseService.shared`
- `ImageStorageManager.shared`
- `PasteService.shared`
- `NotificationService.shared`
- `SoundService.shared`
- `LaunchAtLoginService.shared`

### 2. 观察者模式（Observer）
- 使用 SwiftUI 的 `@State`、`@StateObject`、`@ObservedObject`
- 使用 `NotificationCenter` 传递全局事件

### 3. 委托模式（Delegate）
- `NSApplicationDelegateAdaptor` 连接 SwiftUI 和 AppKit

### 4. MVVM 架构
- **Model**: ClipboardItem, Settings
- **View**: SwiftUI 视图
- **ViewModel**: 隐含在视图的 `@State` 中

---

## 🔐 权限要求

| 权限类型 | 用途 | 必需性 |
|---------|------|-------|
| **辅助功能** | 模拟键盘事件（Cmd+V） | 必需 |
| **通知权限** | 发送复制/粘贴通知 | 可选 |
| **文件访问** | 存储图片到 Application Support | 自动授予 |

---

## 💾 数据持久化

### Core Data 实体：ClipboardItem

| 字段 | 类型 | 说明 |
|-----|------|------|
| `id` | UUID | 唯一标识符 |
| `content` | String? | 文本内容（文本类型） |
| `contentHash` | String? | SHA256 哈希值 |
| `createdAt` | Date? | 创建时间 |
| `appSource` | String? | 来源应用名称 |
| `type` | String? | 类型（"text" 或 "image"） |
| `imagePath` | String? | 图片文件路径（图片类型） |
| `imageWidth` | Int32 | 图片宽度 |
| `imageHeight` | Int32 | 图片高度 |

### UserDefaults 存储
- 应用设置（`AppSettings`）
- JSON 编码存储

---

## 🎵 音效系统

**SoundService.swift** 提供两种音效：
- **复制音效**：检测到新的剪贴板内容时播放
- **粘贴音效**：粘贴历史内容时播放

**音效资源：**
- 存储在 `Resources/Sounds/` 目录
- 格式：WAV
- 文件：1.wav - 6.wav（随机播放）

---

## 🔔 通知系统

**NotificationService.swift** 提供三种通知：

### 1. 复制通知
- 显示复制的内容（文本前 50 字符）
- 图片显示尺寸信息

### 2. 粘贴通知
- 确认粘贴操作完成

### 3. 权限提示通知
- 缺少辅助功能权限时提示

---

## 📱 用户界面

### 主窗口（HistoryListView）
- 搜索栏
- 历史记录列表（支持滚动）
- 空状态提示
- 设置按钮（⚙️）

### 设置窗口（SettingsView）
分组布局（Apple 设计风格）：

**1. 用户体验组**
- 通知开关
- 音效开关

**2. 数据管理组**
- 历史记录上限（50/100/200 条）
- 保留时间（3天/7天/永久）
- 图片大小限制（5MB/10MB/20MB）

**3. 系统集成组**
- 全局快捷键设置
- 开机自启动开关

---

## 🔍 搜索功能

### 搜索逻辑
```swift
Core Data NSPredicate
    ↓
NSPredicate(format: "content CONTAINS[cd] %@", searchText)
    ↓
- [c]: 不区分大小写
- [d]: 不区分变音符号（如 é vs e）
    ↓
实时过滤显示
```

---

## ⚡ 性能优化

### 1. 图片去重
- 使用 SHA256 哈希，相同图片只保存一次
- 减少存储空间占用

### 2. 懒加载
- 图片按需从文件系统加载
- 列表使用 SwiftUI 的 `LazyVStack`

### 3. 异步处理
- 数据库操作在后台线程
- UI 更新在主线程

### 4. 定时清理
- 自动删除过期记录
- 清理孤立的图片文件

---

## 🐛 已知问题

### 图片清晰度下降
**原因：** 多次格式转换（TIFF → PNG → NSImage → 剪贴板）

**影响：** 粘贴的图片可能比原图清晰度低

**建议修复：** 直接保存剪贴板原始数据，避免格式转换

---

## 🚀 启动流程总结

```
1. 应用启动
   ↓
2. AppDelegate 初始化所有服务
   ↓
3. ClipboardMonitor 开始监控（0.5s 轮询）
   ↓
4. HotKeyManager 注册全局快捷键
   ↓
5. WindowManager 创建主窗口（隐藏状态）
   ↓
6. 等待用户操作（快捷键/复制内容）
```

---

## 📦 依赖框架

- **SwiftUI**: 用户界面
- **AppKit**: 窗口管理、剪贴板操作
- **Core Data**: 数据持久化
- **CryptoKit**: SHA256 哈希计算
- **Carbon**: 全局快捷键 API
- **ServiceManagement**: 开机自启动（macOS 13+）

---

## 🎯 核心技术亮点

1. ✅ **实时剪贴板监控**：轮询 + 去重机制
2. ✅ **双层存储架构**：文本（数据库）+ 图片（文件系统）
3. ✅ **智能去重**：SHA256 哈希确保内容唯一性
4. ✅ **无缝粘贴**：模拟键盘事件 + 窗口管理
5. ✅ **优雅 UI**：毛玻璃效果 + Apple 设计风格
6. ✅ **完整的用户体验**：通知 + 音效 + 快捷键

---

## 📝 版本信息

- **当前分支**: `noglass3`
- **macOS 版本要求**: macOS 14.0+
- **开发语言**: Swift 5.0+
- **UI 框架**: SwiftUI

---

*文档生成时间: 2025-11-30*
*项目路径: /Users/lemonstyle/Documents/xcode_pj/pas_cc/PasteMine*
