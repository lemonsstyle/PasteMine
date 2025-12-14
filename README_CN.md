<div align="center">
  <img src=".github/logo.png" width="128" height="128" alt="PasteMine Logo">

  # PasteMine

一款强大的 macOS 剪贴板历史管理工具

中文文档 | [English](./README.md)

</div>

## 功能特性

- **剪贴板历史**: 自动记录剪贴板历史，支持文本、图片和文件
- **快速访问**: 使用可自定义的快捷键即时访问剪贴板历史
- **智能粘贴**: 通过辅助功能权限自动粘贴选中的内容
- **隐私保护**:
  - 所有数据仅存储在本地，绝不上传
  - 自动忽略敏感应用（密码管理器、银行应用等）
  - 过滤特定剪贴板类型
  - 随时清空历史记录
- **音效反馈**: 可选的复制/粘贴音效提示
- **开机启动**: 系统启动时自动运行
- **现代界面**: 基于 SwiftUI 构建的简洁原生 macOS 界面

## 系统要求

- macOS 14.0 或更高版本
- Xcode 15.0 或更高版本（从源码构建时需要）

## 安装

### 下载

从 [Releases](https://github.com/lemonsstyle/PasteMine_App_Store/releases) 页面下载最新版本。

### 从源码构建

1. 克隆仓库：
```bash
git clone https://github.com/lemonsstyle/PasteMine_App_Store.git
cd PasteMine_Compliance
```

2. 使用 Xcode 打开项目：
```bash
open PasteMine/PasteMine.xcodeproj
```

3. 配置开发团队：
   - 在 Xcode 中选择 PasteMine 项目
   - 进入 "Signing & Capabilities"
   - 设置你的 Development Team ID
   - 修改 Bundle Identifier

4. 构建并运行 (⌘R)

## 使用说明

### 首次启动

首次启动时，PasteMine 会引导你完成设置流程：

1. **剪贴板监控**: 启用剪贴板历史记录功能
2. **通知权限**: 允许复制/粘贴操作的通知提醒
3. **辅助功能**: 授予辅助功能权限以使用自动粘贴功能

### 快捷键

- **⌃⌥V**: 打开剪贴板历史窗口（可自定义）
- **↑/↓**: 在历史记录中导航
- **回车**: 粘贴选中的内容
- **⌘D**: 删除选中的记录
- **⌘K**: 清空所有历史
- **ESC**: 关闭窗口

### 设置

点击历史窗口中的齿轮图标访问设置：

- **通用**: 配置快捷键和开机启动
- **隐私**: 管理忽略的应用和剪贴板类型
- **音效**: 启用/禁用音效反馈
- **关于**: 查看应用信息和版本

## 项目结构

```
PasteMine/
├── PasteMine/
│   ├── PasteMine.xcodeproj/      # Xcode 项目文件
│   ├── PasteMine/                # 源代码
│   │   ├── App/                  # 应用生命周期
│   │   ├── Managers/             # 功能管理器
│   │   ├── Models/               # 数据模型
│   │   ├── Services/             # 业务服务
│   │   ├── Views/                # 用户界面
│   │   ├── Utilities/            # 工具类
│   │   └── Resources/            # 资源和音效
│   └── PrivacyInfo.xcprivacy     # 隐私清单
├── Scripts/                       # 构建脚本
├── LICENSE                        # MIT 许可证
└── README.md                      # 项目说明
```

## 隐私保护

PasteMine 重视你的隐私：

- ✅ 所有数据仅存储在本地 Application Support 目录
- ✅ 无网络请求或数据传输
- ✅ 无第三方 SDK 或分析工具
- ✅ 符合 Apple 隐私清单要求
- ✅ 开源代码 - 可自行审查

## 贡献

欢迎贡献！请阅读 [CONTRIBUTING.md](./CONTRIBUTING.md) 了解详情。

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](./LICENSE) 文件。

## 致谢

使用 SwiftUI 和现代 macOS API 构建。

## 支持

如果遇到任何问题或有建议，请[提交 issue](https://github.com/lemonsstyle/PasteMine_App_Store/issues)。

---

用 ❤️ 制作 by [lemonstyle](https://github.com/lemonsstyle)
