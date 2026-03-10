Pod::Spec.new do |s|
  s.name                  = "ByteHideMonitor"
  s.version               = "1.0.1"
  s.summary               = "Runtime Application Self-Protection (RASP) for iOS"
  s.description           = <<-DESC
    ByteHide Monitor provides runtime protection for iOS applications:
    - Anti-debugging and anti-tampering
    - Jailbreak and simulator detection
    - Memory dump and code injection protection
    - Screen recording and overlay detection
    - Network security monitoring
    - Hardware binding and license validation

    Zero-code integration with automatic initialization.
  DESC

  s.homepage              = "https://www.bytehide.com/products/monitor"
  s.documentation_url     = "https://docs.bytehide.com/monitor/ios"
  s.license               = { :type => "Commercial", :file => "LICENSE.txt" }
  s.author                = { "ByteHide" => "support@bytehide.com" }

  s.platform              = :ios, "12.0"
  s.ios.deployment_target = "12.0"
  s.swift_version         = "5.0"

  s.source = {
    :http => "https://github.com/bytehide/ByteHideMonitor-iOS/releases/download/v1.0.1/ByteHideMonitor.xcframework.zip",
    :type => "zip"
  }

  s.vendored_frameworks = "ByteHideMonitor.xcframework"

  s.preserve_paths = [
    "Scripts/validate-license.sh",
    "LICENSE.txt"
  ]

  s.frameworks = "Foundation", "UIKit", "Security"
  s.requires_arc = true
  s.static_framework = false
  s.module_name = "ByteHideMonitor"
end
