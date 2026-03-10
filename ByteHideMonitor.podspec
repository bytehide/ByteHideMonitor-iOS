Pod::Spec.new do |s|
  s.name                  = "ByteHideMonitor"
  s.version               = "1.0.8"
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
  s.documentation_url     = "https://docs.bytehide.com/platforms/ios/products/monitor"
  s.license               = { :type => "Commercial", :text => "Copyright (c) 2025-2026 ByteHide. All rights reserved." }
  s.author                = { "ByteHide" => "support@bytehide.com" }

  s.platform              = :ios, "12.0"
  s.ios.deployment_target = "12.0"
  s.swift_version         = "5.0"

  s.source = {
    :http => "https://github.com/bytehide/ByteHideMonitor-iOS/releases/download/v1.0.8/ByteHideMonitor.xcframework.zip",
    :type => "zip"
  }

  s.vendored_frameworks = "ByteHideMonitor.xcframework"

  s.preserve_paths = [
    "Scripts/sign-assembly.sh",
    "Scripts/setup.sh",
    "Scripts/setup-spm.rb"
  ]

  s.script_phase = {
    :name => "ByteHide Monitor - Sign Assembly",
    :script => '"${PODS_ROOT}/ByteHideMonitor/Scripts/sign-assembly.sh"'
  }

  s.frameworks = "Foundation", "UIKit", "Security"
  s.requires_arc = true
  s.static_framework = false
  s.module_name = "ByteHideMonitor"
end
