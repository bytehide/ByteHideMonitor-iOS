# ByteHide Monitor for iOS

**Runtime Application Self-Protection (RASP)** for iOS applications by [ByteHide](https://www.bytehide.com).

ByteHide Monitor protects your iOS app at runtime against reverse engineering, tampering, debugging, and other security threats. It works automatically with zero code changes.

## Features

- Anti-debugging and anti-tampering protection
- Jailbreak and simulator detection
- Memory dump and code injection protection
- Library injection (DYLD) detection
- Screen recording and screenshot detection
- UI overlay detection
- Network tampering detection (SSL proxies, VPNs)
- Clock tampering detection
- Hardware binding and keychain integrity
- Configurable threat responses (log, close, erase data)
- Cloud configuration and remote updates
- Offline protection (no network required at runtime)

## Requirements

- iOS 12.0+
- Xcode 14.0+
- A valid ByteHide license ([get one here](https://www.bytehide.com/products/monitor))

## Installation

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'ByteHideMonitor'
```

Then run:

```bash
pod install
```

CocoaPods configures everything automatically (build phase, signing script).

### Swift Package Manager

1. In Xcode, go to **File > Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/bytehide/ByteHideMonitor-iOS
   ```
3. From your project directory, run the setup script:
   ```bash
   bash <(curl -sL https://raw.githubusercontent.com/bytehide/ByteHideMonitor-iOS/main/Scripts/setup.sh)
   ```

The setup script adds the signing build phase, disables script sandboxing, and creates the configuration file.

For detailed steps see [SPM installation guide](./docs/install-spm.md).

## Configuration

Create `monitor-config.json` in your project root:

```json
{
  "apiToken": "bh_your_project_key"
}
```

Get your project key at [cloud.bytehide.com](https://cloud.bytehide.com/product/monitor/).

Alternatively, set the token via **Info.plist** or **environment variable**. See the [CocoaPods guide](./docs/install-cocoapods.md) for all options.

## How it works

**Build time:** A build phase script validates your license with the ByteHide API and generates a cryptographic signature (`monitor.sig`) that is embedded in the app bundle.

**Runtime:** ByteHide Monitor auto-initializes before `main()` via `+load()`. It reads the signature, validates it offline, and starts the protection modules. No code changes needed.

## Documentation

- [CocoaPods installation](./docs/install-cocoapods.md)
- [SPM installation](./docs/install-spm.md)
- [Full integration guide](./docs/INTEGRATION-GUIDE.md)

## Support

- Email: support@bytehide.com
- Documentation: [docs.bytehide.com](https://docs.bytehide.com)

## License

This software is proprietary and commercially licensed by **ByteHide Solutions S.L.**

Use of ByteHide Monitor requires a valid, paid license. Unauthorized use, copying, modification, or distribution is strictly prohibited. See [LICENSE](./LICENSE.txt) for full terms.
