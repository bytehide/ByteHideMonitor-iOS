# ByteHide Monitor - iOS

Runtime Application Self-Protection (RASP) for iOS applications.

## Installation

ByteHide Monitor supports both **CocoaPods** and **Swift Package Manager**.

### CocoaPods (Recommended - Zero Config)

```ruby
pod 'ByteHideMonitor', '~> 1.0.0'
```

Then run:
```bash
pod install
```

**Done!** Build-time validation runs automatically.

### Swift Package Manager (One-Time Setup)

See [README-SPM.md](./README-SPM.md) for detailed instructions.

> **Note:** SPM requires running a one-time setup script due to Apple's architecture limitations.

## Quick Start

ByteHide Monitor **auto-initializes** - no code required!

Just configure your token and build:

### Option 1: Environment Variable

1. Edit Scheme → Run → Environment Variables
2. Add: `BYTEHIDE_TOKEN` = `your-token-here`

### Option 2: Info.plist

```xml
<key>ByteHideMonitor</key>
<dict>
    <key>APIToken</key>
    <string>${BYTEHIDE_TOKEN}</string>
</dict>
```

### Option 3: JSON Configuration

Create `monitor-config.json`:

```json
{
  "apiToken": "${BYTEHIDE_TOKEN}",
  "protections": [
    {
      "type": "DebuggerDetection",
      "action": "close",
      "intervalMs": 60000
    }
  ]
}
```

## Documentation

- **[Integration Guide](./docs/INTEGRATION-GUIDE.md)** - Complete setup guide
- **[CocoaPods Implementation](./COCOAPODS_IMPLEMENTATION.md)** - Technical details for CocoaPods
- **[SPM Guide](./README-SPM.md)** - Swift Package Manager setup
- **[SPM Implementation](./SPM-IMPLEMENTATION.md)** - Technical details for SPM

## Features

- ✅ **Zero-code auto-initialization** - Works via `+load()` before `main()`
- ✅ **Build-time license validation** - Validates token during compilation
- ✅ **Runtime protections** - Debugger, jailbreak, clock tampering detection
- ✅ **Custom actions** - Define your own threat responses
- ✅ **Cloud configuration** - Remote protection updates
- ✅ **Offline mode** - Works without network connection
- ✅ **JSON configuration** - Flexible setup options

## How It Works

### Build Time (Automatic)

1. CocoaPods/SPM build script runs
2. Reads token from environment/Info.plist/JSON
3. Validates token with ByteHide API
4. Downloads JWT signature
5. Saves `monitor.sig` to app bundle

### Runtime (Automatic)

1. `+load()` executes before `main()`
2. Reads `monitor.sig` from app bundle
3. Validates JWT signature
4. Initializes protection modules
5. Starts threat detection

**No code required** - everything is automatic!

## Requirements

- iOS 12.0+
- Xcode 13.0+
- CocoaPods 1.10+ OR Swift Package Manager 5.6+

## Support

- 📧 Email: support@bytehide.com
- 💬 Discord: [discord.gg/bytehide](https://discord.gg/bytehide)
- 📚 Docs: [docs.bytehide.com](https://docs.bytehide.com)
- 🐛 Issues: [github.com/bytehide/monitor-ios/issues](https://github.com/bytehide/monitor-ios/issues)

## License

Proprietary - Requires valid ByteHide subscription.

---

**ByteHide Monitor** - Enterprise-grade RASP for iOS
