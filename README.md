<div align="center">
  <img src=".github/logo.png" width="128" height="128" alt="PasteMine Logo">

  # PasteMine

A powerful clipboard history manager for macOS

[中文文档](./README_CN.md) | English

</div>

## Features

- **Clipboard History**: Automatically records your clipboard history with support for text, images, and files
- **Quick Access**: Use customizable keyboard shortcuts to instantly access your clipboard history
- **Smart Paste**: Automatically paste selected items with accessibility permissions
- **Privacy Protection**:
  - All data stored locally, never uploaded
  - Ignore sensitive apps (password managers, banking apps, etc.)
  - Filter specific clipboard types
  - Clear history anytime
- **Sound Effects**: Optional sound feedback for copy/paste actions
- **Launch at Login**: Automatically start with your system
- **Modern UI**: Clean, native macOS interface built with SwiftUI

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for building from source)

## Installation

### Download

Download the latest release from the [Releases](https://github.com/lemonsstyle/PasteMine_App_Store/releases) page.

### Build from Source

1. Clone the repository:
```bash
git clone https://github.com/lemonsstyle/PasteMine_App_Store.git
cd PasteMine_Compliance
```

2. Open the project in Xcode:
```bash
open PasteMine/PasteMine.xcodeproj
```

3. Configure your development team:
   - Select the PasteMine project in Xcode
   - Go to "Signing & Capabilities"
   - Set your Development Team ID
   - Update the Bundle Identifier

4. Build and run (⌘R)

## Usage

### First Launch

On first launch, PasteMine will guide you through the setup process:

1. **Clipboard Monitoring**: Enable clipboard history recording
2. **Notifications**: Allow notifications for copy/paste actions
3. **Accessibility**: Grant accessibility permissions for auto-paste feature

### Keyboard Shortcuts

- **⌃⌥V**: Open clipboard history window (customizable)
- **↑/↓**: Navigate through history items
- **Enter**: Paste selected item
- **⌘D**: Delete selected item
- **⌘K**: Clear all history
- **ESC**: Close window

### Settings

Access settings by clicking the gear icon in the history window:

- **General**: Configure keyboard shortcuts and launch at login
- **Privacy**: Manage ignored apps and clipboard types
- **Sound**: Enable/disable sound effects
- **About**: View app information and version

## Project Structure

```
PasteMine/
├── PasteMine/
│   ├── PasteMine.xcodeproj/      # Xcode project
│   ├── PasteMine/                # Source code
│   │   ├── App/                  # App lifecycle
│   │   ├── Managers/             # Feature managers
│   │   ├── Models/               # Data models
│   │   ├── Services/             # Business services
│   │   ├── Views/                # UI views
│   │   ├── Utilities/            # Utility classes
│   │   └── Resources/            # Assets and sounds
│   └── PrivacyInfo.xcprivacy     # Privacy manifest
├── Scripts/                       # Build scripts
├── LICENSE                        # MIT License
└── README.md                      # This file
```

## Privacy

PasteMine respects your privacy:

- ✅ All data stored locally in Application Support
- ✅ No network requests or data transmission
- ✅ No third-party SDKs or analytics
- ✅ Compliant with Apple's Privacy Manifest requirements
- ✅ Open source - audit the code yourself

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## Acknowledgments

Built with SwiftUI and modern macOS APIs.

## Support

If you encounter any issues or have suggestions, please [open an issue](https://github.com/lemonsstyle/PasteMine_App_Store/issues).

---

Made with ❤️ by [lemonstyle](https://github.com/lemonsstyle)
