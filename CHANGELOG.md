# Changelog

All notable changes to ByteHide Monitor iOS will be documented in this file.

## [1.0.5] - 2026-03-10

### Added
- Initial iOS release
- CocoaPods and Swift Package Manager support
- Auto-initialization via +load() (zero code required)
- Build-time assembly signing with JWT signatures
- Runtime protection modules:
  - Debugger detection (native + P_TRACED)
  - Jailbreak detection (files, URLs, sandbox, symlinks)
  - Clock tampering detection
  - Memory dump detection
  - Simulator detection
  - App tampering detection
  - Network tampering detection (SSL proxies, VPNs)
  - Process injection detection
  - Library injection detection (DYLD)
  - Screen recording detection
  - Screenshot detection
  - UI overlay detection
  - Hardware binding validation
  - Keychain integrity detection
- Configurable actions: Close, Erase, Log, NoOp, Custom
- JSON configuration support (monitor-config.json)
- Info.plist configuration support
- Environment variable configuration (BYTEHIDE_TOKEN)
- Cloud configuration sync
- Offline mode with local protection
- Heartbeat monitoring
- Incident queue with batch reporting
