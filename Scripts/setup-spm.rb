#!/usr/bin/env ruby

# ByteHide Monitor - SPM Setup Script
#
# Configures your Xcode project for ByteHide Monitor with SPM:
#   1. Adds "Sign Assembly" build phase to app target(s)
#   2. Disables User Script Sandboxing (required for network requests)
#
# Usage:
#   ruby setup-spm.rb                           # Auto-detect .xcodeproj
#   ruby setup-spm.rb MyApp.xcodeproj            # Specific project
#
# One-liner (from your project directory):
#   bash <(curl -sL https://raw.githubusercontent.com/bytehide/ByteHideMonitor-iOS/main/Scripts/setup.sh)

begin
  require 'xcodeproj'
rescue LoadError
  puts "\033[0;31mxcodeproj gem not found.\033[0m"
  puts ""
  puts "Install it with:"
  puts "  gem install xcodeproj"
  puts ""
  puts "Or use the setup.sh wrapper which installs it automatically:"
  puts "  bash <(curl -sL https://raw.githubusercontent.com/bytehide/ByteHideMonitor-iOS/main/Scripts/setup.sh)"
  exit 1
end

# ANSI colors
RED    = "\033[0;31m"
GREEN  = "\033[0;32m"
YELLOW = "\033[1;33m"
BLUE   = "\033[0;34m"
NC     = "\033[0m"

# The script that will be embedded in the build phase.
# Uses ${BUILD_DIR} which Xcode resolves at build time to find the SPM checkout.
SIGN_SCRIPT = <<~'BASH'
SCRIPT="${BUILD_DIR}/../../SourcePackages/checkouts/ByteHideMonitor-iOS/Scripts/sign-assembly.sh"
if [ -f "$SCRIPT" ]; then
    bash "$SCRIPT"
else
    echo "warning: ByteHide Monitor sign-assembly.sh not found at $SCRIPT"
    echo "warning: Make sure ByteHideMonitor-iOS is added as a Swift Package dependency"
fi
BASH

BUILD_PHASE_NAME = "ByteHide Monitor - Sign Assembly"

# ─── Helpers ────────────────────────────────────────────────────────────────

def print_success(msg) puts "#{GREEN}  ✓ #{msg}#{NC}" end
def print_error(msg)   puts "#{RED}  ✗ #{msg}#{NC}" end
def print_warning(msg) puts "#{YELLOW}  ⚠ #{msg}#{NC}" end
def print_info(msg)    puts "#{BLUE}  ℹ #{msg}#{NC}" end

# ─── Find .xcodeproj ────────────────────────────────────────────────────────

def find_xcodeproj(provided_path = nil)
  if provided_path && provided_path.end_with?('.xcodeproj')
    return provided_path if File.exist?(provided_path)
    print_error "Project not found: #{provided_path}"
    return nil
  end

  projects = Dir.glob('*.xcodeproj').reject { |p| p.include?('Pods') }

  if projects.empty?
    print_error "No .xcodeproj found in current directory"
    puts ""
    puts "  Run this script from your Xcode project directory:"
    puts "    #{BLUE}cd /path/to/YourProject#{NC}"
    puts "    #{BLUE}bash <(curl -sL https://raw.githubusercontent.com/bytehide/ByteHideMonitor-iOS/main/Scripts/setup.sh)#{NC}"
    return nil
  end

  if projects.length > 1
    print_warning "Multiple .xcodeproj found:"
    projects.each_with_index { |p, i| puts "    #{i + 1}. #{p}" }
    print "  Select project (1-#{projects.length}): "
    selection = gets.chomp.to_i
    return projects[selection - 1] if selection > 0 && selection <= projects.length
    print_error "Invalid selection"
    return nil
  end

  projects.first
end

# ─── Add build phase ────────────────────────────────────────────────────────

def setup_build_phase(project, target)
  # Check if already exists
  existing = target.shell_script_build_phases.find { |p| p.name == BUILD_PHASE_NAME }

  if existing
    print_warning "Build phase already exists in '#{target.name}' — updating"
    existing.shell_script = SIGN_SCRIPT
    return :updated
  end

  # Create new build phase
  phase = target.new_shell_script_build_phase(BUILD_PHASE_NAME)
  phase.shell_script = SIGN_SCRIPT
  phase.output_paths = ['$(BUILT_PRODUCTS_DIR)/$(PRODUCT_NAME).app/monitor.sig']

  # Move before Compile Sources (top of build phases)
  compile_index = target.build_phases.index { |p| p.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }
  if compile_index
    target.build_phases.delete(phase)
    target.build_phases.insert(compile_index, phase)
  end

  print_success "Added build phase to '#{target.name}' (before Compile Sources)"
  :added
end

# ─── Disable sandbox ────────────────────────────────────────────────────────

def disable_sandbox(target)
  target.build_configurations.each do |config|
    current = config.build_settings['USER_SCRIPT_SANDBOXING']
    if current == 'NO'
      next
    end
    config.build_settings['USER_SCRIPT_SANDBOXING'] = 'NO'
  end
  print_success "Disabled User Script Sandboxing in '#{target.name}'"
end

# ─── Main ────────────────────────────────────────────────────────────────────

def main
  puts ""
  puts "#{BLUE}╔══════════════════════════════════════════════════════════╗#{NC}"
  puts "#{BLUE}║       ByteHide Monitor — SPM Setup                     ║#{NC}"
  puts "#{BLUE}╚══════════════════════════════════════════════════════════╝#{NC}"
  puts ""

  # Find project
  project_path = find_xcodeproj(ARGV[0])
  return unless project_path

  print_info "Opening: #{project_path}"
  project = Xcodeproj::Project.open(project_path)

  # Find app targets
  app_targets = project.targets.select do |t|
    t.is_a?(Xcodeproj::Project::Object::PBXNativeTarget) &&
      t.product_type == 'com.apple.product-type.application'
  end

  if app_targets.empty?
    print_error "No application targets found"
    return
  end

  print_info "Found #{app_targets.length} app target(s): #{app_targets.map(&:name).join(', ')}"
  puts ""

  # Setup each target
  app_targets.each do |target|
    setup_build_phase(project, target)
    disable_sandbox(target)
  end

  # Save
  puts ""
  print_info "Saving project..."
  project.save
  print_success "Project saved"

  # Summary
  puts ""
  puts "#{GREEN}╔══════════════════════════════════════════════════════════╗#{NC}"
  puts "#{GREEN}║                    Setup complete!                      ║#{NC}"
  puts "#{GREEN}╚══════════════════════════════════════════════════════════╝#{NC}"
  puts ""
  puts "  Next steps:"
  puts ""
  puts "  1. Add your API token — create #{BLUE}monitor-config.json#{NC} in your project root:"
  puts "     #{BLUE}{ \"apiToken\": \"bh_your_project_key\" }#{NC}"
  puts ""
  puts "  2. Build your project — signing runs automatically!"
  puts ""
  puts "  Get your token at: #{BLUE}https://monitor.bytehide.com#{NC}"
  puts ""
end

begin
  main
rescue => e
  print_error "Error: #{e.message}"
  puts e.backtrace.first(3).map { |l| "    #{l}" }.join("\n") if ENV['DEBUG']
  exit 1
end
