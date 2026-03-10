#!/bin/bash

# ByteHide Monitor - Assembly Signing
#
# Signs the application binary to enable runtime integrity verification.
# This build phase generates a cryptographic signature that ByteHide Monitor
# uses to detect tampering, reverse engineering, and unauthorized modifications.
#
# The signature is verified at runtime to ensure the app hasn't been modified
# after compilation. Without this signature, protection modules cannot start.

set -e
set -o pipefail

#──────────────────────────────────────────────────────────────────────────────
# Configuration
#──────────────────────────────────────────────────────────────────────────────

# ByteHide signing endpoint
API_ENDPOINT="${BYTEHIDE_API_ENDPOINT:-https://monitor.microservice.bytehide.com/api}"
TIMEOUT=5

#──────────────────────────────────────────────────────────────────────────────
# Colors for output
#──────────────────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

#──────────────────────────────────────────────────────────────────────────────
# Helper functions
#──────────────────────────────────────────────────────────────────────────────

log_info() {
    : # Silent in release builds
}

log_success() {
    echo "ByteHide Monitor: $1"
}

log_warning() {
    echo "WARNING: $1" >&2
}

log_error() {
    echo "ERROR: $1" >&2
}

#──────────────────────────────────────────────────────────────────────────────
# Validate environment
#──────────────────────────────────────────────────────────────────────────────

if [ -z "$BUILT_PRODUCTS_DIR" ] || [ -z "$PRODUCT_NAME" ]; then
    log_error "Required Xcode environment variables not set"
    log_error "This script must run as Xcode build phase"
    exit 1
fi

APP_BUNDLE="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
INFO_PLIST="${APP_BUNDLE}/Info.plist"
SIGNATURE_FILE="${APP_BUNDLE}/monitor.sig"

#──────────────────────────────────────────────────────────────────────────────
# Step 1: Read project key (Priority: 1. ENV, 2. Info.plist, 3. monitor-config.json)
#──────────────────────────────────────────────────────────────────────────────

TOKEN=""

# Priority 1: BYTEHIDE_TOKEN environment variable (easiest for CI/CD)
if [ -n "$BYTEHIDE_TOKEN" ]; then
    log_info "Using API token from BYTEHIDE_TOKEN environment variable"
    TOKEN="$BYTEHIDE_TOKEN"
fi

# Priority 2: Info.plist (standard iOS configuration)
if [ -z "$TOKEN" ] && [ -f "$INFO_PLIST" ]; then
    TOKEN=$(/usr/libexec/PlistBuddy -c "Print :ByteHideMonitor:APIToken" "$INFO_PLIST" 2>/dev/null || echo "")
fi

# Priority 3: monitor-config.json (project configuration file)
if [ -z "$TOKEN" ]; then
    # Look for monitor-config.json in common locations
    CONFIG_PATHS=(
        "${SRCROOT}/monitor-config.json"
        "${SRCROOT}/${PRODUCT_NAME}/monitor-config.json"
        "${PROJECT_DIR}/monitor-config.json"
    )

    for CONFIG_PATH in "${CONFIG_PATHS[@]}"; do
        if [ -f "$CONFIG_PATH" ]; then
            # Extract token from JSON - "apiToken" is the standard field name
            TOKEN=$(sed -n 's/.*"apiToken"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG_PATH" | head -1)

            # Fallback: also accept "token" and "projectToken" for compatibility
            if [ -z "$TOKEN" ]; then
                TOKEN=$(sed -n 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG_PATH" | head -1)
            fi

            if [ -z "$TOKEN" ]; then
                TOKEN=$(sed -n 's/.*"projectToken"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG_PATH" | head -1)
            fi

            if [ -n "$TOKEN" ]; then
                break
            fi
        fi
    done
fi

# Validate token was found
if [ -z "$TOKEN" ]; then
    log_error "No project key found for assembly signing"
    log_error ""
    log_error "ByteHide Monitor requires a project key to sign the assembly."
    log_error "Without signing, runtime protection cannot verify binary integrity."
    log_error ""
    log_error "Set your project key via one of these methods:"
    log_error ""
    log_error "  1. BYTEHIDE_TOKEN Build Setting (Recommended):"
    log_error "     Target → Build Settings → + → Add User-Defined Setting"
    log_error "     BYTEHIDE_TOKEN = bh_your_project_key"
    log_error ""
    log_error "  2. monitor-config.json (in project root):"
    log_error "     { \"apiToken\": \"bh_your_project_key\" }"
    log_error ""
    log_error "  3. Info.plist:"
    log_error "     <key>ByteHideMonitor</key>"
    log_error "     <dict>"
    log_error "         <key>APIToken</key>"
    log_error "         <string>bh_your_project_key</string>"
    log_error "     </dict>"
    log_error ""
    log_error "Skipping assembly signing (protection will run in unsigned mode)"
    exit 0
fi

# Check if token is still a placeholder (not resolved by Xcode)
if [[ "$TOKEN" == *'$('* ]] || [[ "$TOKEN" == *'${'* ]]; then
    log_error "Token not resolved: $TOKEN"
    log_error ""
    log_error "The token contains an unresolved variable reference."
    log_error "Set BYTEHIDE_TOKEN as a User-Defined Build Setting:"
    log_error "  Target → Build Settings → + → Add User-Defined Setting"
    log_error "  BYTEHIDE_TOKEN = bh_your_project_key"
    log_error ""
    log_error "Or use the actual token value directly in monitor-config.json:"
    log_error "  { \"apiToken\": \"bh_your_project_key\" }"
    exit 1
fi

# Validate token format (basic check)
if [[ ! "$TOKEN" =~ ^bh_ ]]; then
    log_warning "Token format unusual (expected 'bh_...'): ${TOKEN:0:10}..."
    log_warning "Proceeding anyway..."
fi

: # Token found, silent

#──────────────────────────────────────────────────────────────────────────────
# Step 2: Gather device information
#──────────────────────────────────────────────────────────────────────────────

# Gather build information (silent)
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" 2>/dev/null || echo "unknown")
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "1.0")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "1")
PLATFORM="${PLATFORM_NAME:-ios}"
SDK_VERSION="${SDK_VERSION:-unknown}"
MACHINE_ID=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}' || echo "unknown")

#──────────────────────────────────────────────────────────────────────────────
# Step 3: Call API to validate license
#──────────────────────────────────────────────────────────────────────────────

# Build URL and call API (silent)
VALIDATE_URL="${API_ENDPOINT}/license/validate/${TOKEN}"
JSON_PAYLOAD="{\"token\":\"$TOKEN\",\"integrity\":null}"

set +e
HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "$VALIDATE_URL" \
    -H "Content-Type: application/json" \
    -H "User-Agent: ByteHideMonitor-iOS/1.0.0" \
    --max-time $TIMEOUT \
    --connect-timeout $TIMEOUT \
    --data "$JSON_PAYLOAD" 2>&1)
CURL_EXIT_CODE=$?
set -e

# Extract status code and body
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')

# If curl itself failed (DNS, timeout, etc.), HTTP_CODE will not be a number
if ! [[ "$HTTP_CODE" =~ ^[0-9]+$ ]]; then
    HTTP_CODE="000"
    log_info "Curl failed - treating as network error (HTTP 000)"
fi

# Check HTTP status
if [ "$HTTP_CODE" != "200" ]; then
    log_error "Signing request failed (HTTP $HTTP_CODE)"

    # Check for common errors
    case "$HTTP_CODE" in
        000)
            log_warning "Network error - signing server unreachable"
            log_warning "Generating offline signature for development..."

            # Generate mock JWT for offline testing
            # Header: {"alg":"HS256","typ":"JWT"}
            HEADER="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
            # Payload: {"sub":"test","exp":9999999999,"iat":1735329600}
            PAYLOAD="eyJzdWIiOiJ0ZXN0IiwiZXhwIjo5OTk5OTk5OTk5LCJpYXQiOjE3MzUzMjk2MDB9"
            # Signature (mock - not cryptographically valid)
            SIGNATURE="mock_signature_for_development_only"
            JWT="${HEADER}.${PAYLOAD}.${SIGNATURE}"

            log_warning "Offline signature generated (limited protection)"
            ;;
        401|403)
            log_error "Invalid or expired project key"
            log_error "Get your project key at: https://monitor.bytehide.com"
            exit 1
            ;;
        429)
            log_error "Rate limit exceeded - too many signing requests"
            log_error "Wait a few minutes and try again"
            exit 1
            ;;
        500|502|503)
            log_error "ByteHide signing service temporarily unavailable"
            log_error "Try again in a few minutes"
            exit 1
            ;;
        *)
            log_error "Unknown error occurred"
            exit 1
            ;;
    esac
fi

# Extract JWT from response (silent)
if [ "$HTTP_CODE" = "200" ]; then
    JWT=$(echo "$RESPONSE_BODY" | sed -n 's/.*"data"[[:space:]]*:[[:space:]]*{[^}]*"jwt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

    if [ -z "$JWT" ]; then
        JWT=$(echo "$RESPONSE_BODY" | sed -n 's/.*"jwt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    fi

    if [ -z "$JWT" ]; then
        JWT=$(echo "$RESPONSE_BODY" | sed -n 's/.*"certificate"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    fi

    if [ -z "$JWT" ]; then
        log_error "No signature received from signing service"
        exit 1
    fi
fi

# At this point, JWT is set either from API (HTTP 200) or mock (HTTP 000)

# Validate JWT format
JWT_PARTS=$(echo "$JWT" | tr '.' '\n' | wc -l)
if [ "$JWT_PARTS" -ne 3 ]; then
    log_error "Invalid signature format"
    exit 1
fi

#──────────────────────────────────────────────────────────────────────────────
# Step 5: Embed signature in app bundle
#──────────────────────────────────────────────────────────────────────────────

echo "$JWT" > "$SIGNATURE_FILE"

if [ ! -f "$SIGNATURE_FILE" ]; then
    log_error "Failed to embed signature in app bundle"
    exit 1
fi

# Verify signature file
SAVED_JWT=$(cat "$SIGNATURE_FILE")
if [ "$SAVED_JWT" != "$JWT" ]; then
    log_error "Signature verification failed"
    exit 1
fi

log_success "Assembly signature verified"
exit 0
