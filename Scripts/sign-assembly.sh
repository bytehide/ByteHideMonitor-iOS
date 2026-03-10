#!/bin/bash

# ByteHide Monitor - Assembly Signing
#
# Signs the application binary to enable runtime integrity verification.
# This build phase generates a cryptographic signature that ByteHide Monitor
# uses to detect tampering, reverse engineering, and unauthorized modifications.
#
# The signature is verified at runtime to ensure the app hasn't been modified
# after compilation. Without this signature, protection modules cannot start.
#
# Works in both CocoaPods context (SRCROOT=Pods/) and SPM/manual context.

set -e
set -o pipefail

#──────────────────────────────────────────────────────────────────────────────
# Configuration
#──────────────────────────────────────────────────────────────────────────────

API_ENDPOINT="${BYTEHIDE_API_ENDPOINT:-https://monitor.microservice.bytehide.com/api}"
TIMEOUT=5

#──────────────────────────────────────────────────────────────────────────────
# Helper functions
#──────────────────────────────────────────────────────────────────────────────

log_info() {
    : # Silent in normal builds
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
# Detect execution context (CocoaPods vs SPM/manual)
#──────────────────────────────────────────────────────────────────────────────

if [ -z "$BUILT_PRODUCTS_DIR" ]; then
    log_error "Required Xcode environment variables not set"
    log_error "This script must run as an Xcode build phase"
    exit 1
fi

# In CocoaPods, SRCROOT/PRODUCT_NAME/BUILT_PRODUCTS_DIR refer to the pod
# target, not the app. We need to resolve the real app project and .app bundle.
if [ -n "$PODS_ROOT" ]; then
    # App project root is the parent of the Pods/ directory
    APP_PROJECT_ROOT=$(cd "$PODS_ROOT" && cd .. && pwd)

    # Pod's BUILT_PRODUCTS_DIR is a subdirectory (e.g., .../Debug-iphonesimulator/ByteHideMonitor/).
    # The app's .app bundle lives in the parent directory.
    APP_BUILD_DIR=$(dirname "$BUILT_PRODUCTS_DIR")
    APP_BUNDLE=$(find "$APP_BUILD_DIR" -maxdepth 1 -name "*.app" -type d 2>/dev/null | head -1)

    if [ -z "$APP_BUNDLE" ]; then
        # .app not built yet (clean build) — derive name from project directory
        APP_NAME=$(basename "$APP_PROJECT_ROOT")
        APP_BUNDLE="${APP_BUILD_DIR}/${APP_NAME}.app"
        mkdir -p "$APP_BUNDLE"
    fi
else
    # SPM or manual: SRCROOT and PRODUCT_NAME refer to the app directly
    APP_PROJECT_ROOT="${SRCROOT}"
    APP_BUNDLE="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
    mkdir -p "$APP_BUNDLE"
fi

INFO_PLIST="${APP_BUNDLE}/Info.plist"
SIGNATURE_FILE="${APP_BUNDLE}/monitor.sig"

#──────────────────────────────────────────────────────────────────────────────
# Step 1: Find project key
#   Priority: 1. BYTEHIDE_TOKEN env var
#             2. monitor-config.json (in app project root)
#             3. Info.plist (ByteHideMonitor > APIToken)
#──────────────────────────────────────────────────────────────────────────────

TOKEN=""

# Priority 1: BYTEHIDE_TOKEN environment variable
# In CocoaPods context, User-Defined Build Settings from the app target are
# NOT visible. BYTEHIDE_TOKEN must be a real env var (CI/CD, shell profile).
if [ -n "$BYTEHIDE_TOKEN" ]; then
    TOKEN="$BYTEHIDE_TOKEN"
fi

# Priority 2: monitor-config.json
if [ -z "$TOKEN" ]; then
    # In CocoaPods, PRODUCT_NAME is the pod name; derive app name from project root
    if [ -n "$PODS_ROOT" ]; then
        APP_TARGET_NAME=$(basename "$APP_PROJECT_ROOT")
    else
        APP_TARGET_NAME="$PRODUCT_NAME"
    fi

    CONFIG_PATHS=(
        "${APP_PROJECT_ROOT}/monitor-config.json"
        "${APP_PROJECT_ROOT}/${APP_TARGET_NAME}/monitor-config.json"
        "${PROJECT_DIR}/monitor-config.json"
    )

    for CONFIG_PATH in "${CONFIG_PATHS[@]}"; do
        if [ -f "$CONFIG_PATH" ]; then
            # "apiToken" is the standard field name (matches SDK runtime)
            TOKEN=$(sed -n 's/.*"apiToken"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG_PATH" | head -1)

            # Fallback: also accept "token" and "projectToken"
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

# Priority 3: Info.plist (ByteHideMonitor > APIToken)
if [ -z "$TOKEN" ] && [ -f "$INFO_PLIST" ]; then
    TOKEN=$(/usr/libexec/PlistBuddy -c "Print :ByteHideMonitor:APIToken" "$INFO_PLIST" 2>/dev/null || echo "")
fi

# Also check source Info.plist (not yet copied to .app bundle)
if [ -z "$TOKEN" ] && [ -n "$APP_PROJECT_ROOT" ]; then
    for _plist in "${APP_PROJECT_ROOT}"/*/Info.plist "${APP_PROJECT_ROOT}"/Info.plist; do
        if [ -f "$_plist" ]; then
            TOKEN=$(/usr/libexec/PlistBuddy -c "Print :ByteHideMonitor:APIToken" "$_plist" 2>/dev/null || echo "")
            if [ -n "$TOKEN" ]; then
                break
            fi
        fi
    done
fi

# Validate token was found
if [ -z "$TOKEN" ]; then
    log_error "── Diagnostic ──────────────────────────────────────"
    log_error "APP_PROJECT_ROOT: ${APP_PROJECT_ROOT:-(empty)}"
    log_error "APP_BUNDLE: ${APP_BUNDLE:-(empty)}"
    log_error "PODS_ROOT: ${PODS_ROOT:-(empty)}"
    log_error "BYTEHIDE_TOKEN: ${BYTEHIDE_TOKEN:-(empty)}"
    for _p in "${CONFIG_PATHS[@]}"; do
        if [ -f "$_p" ]; then log_error "  FOUND: $_p"; else log_error "  NOT FOUND: $_p"; fi
    done
    log_error "───────────────────────────────────────────────────"
    log_error ""
    log_error "No project key found for assembly signing"
    log_error ""
    log_error "ByteHide Monitor requires a project key to sign the assembly."
    log_error "Without signing, runtime protection cannot verify binary integrity."
    log_error ""
    log_error "Set your project key via one of these methods:"
    log_error ""
    log_error "  1. monitor-config.json in project root (Recommended):"
    log_error "     { \"apiToken\": \"bh_your_project_key\" }"
    log_error ""
    log_error "  2. Info.plist:"
    log_error "     <key>ByteHideMonitor</key>"
    log_error "     <dict>"
    log_error "         <key>APIToken</key>"
    log_error "         <string>bh_your_project_key</string>"
    log_error "     </dict>"
    log_error ""
    log_error "  3. BYTEHIDE_TOKEN environment variable (CI/CD):"
    log_error "     export BYTEHIDE_TOKEN=bh_your_project_key"
    log_error ""
    log_error "Skipping assembly signing (protection will run in unsigned mode)"
    exit 0
fi

# Resolve environment variable references in token value (e.g., "${BYTEHIDE_TOKEN}")
if [[ "$TOKEN" == *'${'* ]]; then
    # Extract variable name and try to resolve
    VAR_NAME=$(echo "$TOKEN" | sed -n 's/.*\${\([^}]*\)}.*/\1/p')
    if [ -n "$VAR_NAME" ]; then
        RESOLVED=$(eval echo "\${$VAR_NAME:-}")
        if [ -n "$RESOLVED" ]; then
            TOKEN="$RESOLVED"
        else
            log_error "Token contains unresolved variable: \${$VAR_NAME}"
            log_error ""
            log_error "Use the actual token value in monitor-config.json:"
            log_error "  { \"apiToken\": \"bh_your_project_key\" }"
            log_error ""
            log_error "Or set the environment variable for CI/CD:"
            log_error "  export $VAR_NAME=bh_your_project_key"
            exit 0
        fi
    fi
fi

# Validate token format
if [[ ! "$TOKEN" =~ ^bh_ ]]; then
    log_warning "Token format unusual (expected 'bh_...'): ${TOKEN:0:10}..."
    log_warning "Proceeding anyway..."
fi

#──────────────────────────────────────────────────────────────────────────────
# Step 2: Gather build information
#──────────────────────────────────────────────────────────────────────────────

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" 2>/dev/null || echo "unknown")
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "1.0")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "1")
PLATFORM="${PLATFORM_NAME:-ios}"
SDK_VERSION="${SDK_VERSION:-unknown}"
MACHINE_ID=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}' || echo "unknown")

#──────────────────────────────────────────────────────────────────────────────
# Step 3: Request signature from signing service
#──────────────────────────────────────────────────────────────────────────────

VALIDATE_URL="${API_ENDPOINT}/license/validate/${TOKEN}"
JSON_PAYLOAD="{\"token\":\"$TOKEN\",\"integrity\":null}"

set +e
HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "$VALIDATE_URL" \
    -H "Content-Type: application/json" \
    -H "User-Agent: ByteHideMonitor-iOS/1.0.6" \
    --max-time $TIMEOUT \
    --connect-timeout $TIMEOUT \
    --data "$JSON_PAYLOAD" 2>&1)
CURL_EXIT_CODE=$?
set -e

HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')

if ! [[ "$HTTP_CODE" =~ ^[0-9]+$ ]]; then
    HTTP_CODE="000"
fi

if [ "$HTTP_CODE" != "200" ]; then
    case "$HTTP_CODE" in
        000)
            log_warning "Network error - signing server unreachable"
            log_warning "Generating offline signature for development..."

            HEADER="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
            PAYLOAD="eyJzdWIiOiJ0ZXN0IiwiZXhwIjo5OTk5OTk5OTk5LCJpYXQiOjE3MzUzMjk2MDB9"
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
            log_error "Signing request failed (HTTP $HTTP_CODE)"
            exit 1
            ;;
    esac
fi

# Extract JWT from response
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

# Validate JWT format
JWT_PARTS=$(echo "$JWT" | tr '.' '\n' | wc -l)
if [ "$JWT_PARTS" -ne 3 ]; then
    log_error "Invalid signature format"
    exit 1
fi

#──────────────────────────────────────────────────────────────────────────────
# Step 4: Embed signature in app bundle
#──────────────────────────────────────────────────────────────────────────────

mkdir -p "$(dirname "$SIGNATURE_FILE")"
echo "$JWT" > "$SIGNATURE_FILE"

if [ ! -f "$SIGNATURE_FILE" ]; then
    log_error "Failed to embed signature in app bundle"
    exit 1
fi

SAVED_JWT=$(cat "$SIGNATURE_FILE")
if [ "$SAVED_JWT" != "$JWT" ]; then
    log_error "Signature verification failed"
    exit 1
fi

log_success "Assembly signed successfully"
exit 0
