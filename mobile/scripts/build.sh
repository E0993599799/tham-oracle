#!/bin/bash
#
# 6J: Build and Deploy Script
# Builds iOS and Android binaries for Omega OS Mobile
#
# Usage:
#   bash scripts/build.sh ios       — Build iOS app
#   bash scripts/build.sh android   — Build Android app
#   bash scripts/build.sh all       — Build both
#

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_LOG="$REPO_ROOT/logs/mobile-build-$(date +%Y%m%d-%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "$REPO_ROOT/logs"

log() {
  echo -e "${GREEN}[BUILD]${NC} $1" | tee -a "$BUILD_LOG"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1" | tee -a "$BUILD_LOG"
  exit 1
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$BUILD_LOG"
}

log "Omega OS Mobile — Build Script"
log "Build started at $(date)"
log "Logging to: $BUILD_LOG"

# Check prerequisites
log "Checking prerequisites..."
command -v node >/dev/null 2>&1 || error "Node.js not installed"
command -v npm >/dev/null 2>&1 || error "npm not installed"

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)

log "Node.js: $NODE_VERSION"
log "npm: $NPM_VERSION"

# Install dependencies
log "Installing dependencies..."
cd "$REPO_ROOT"
npm install >> "$BUILD_LOG" 2>&1 || error "npm install failed"

# TypeScript type check
log "Running TypeScript type check..."
npm run type-check >> "$BUILD_LOG" 2>&1 || warn "Type check failed (non-blocking)"

# Lint
log "Running linter..."
npm run lint >> "$BUILD_LOG" 2>&1 || warn "Linting issues found (non-blocking)"

# Build target
TARGET="${1:-all}"

build_ios() {
  log "Building iOS app..."

  if ! command -v xcodebuild >/dev/null 2>&1; then
    error "Xcode not installed. Run: brew install xcode-select"
  fi

  cd "$REPO_ROOT/ios"

  log "Installing CocoaPods..."
  pod install >> "$BUILD_LOG" 2>&1 || error "pod install failed"

  log "Building with xcodebuild..."
  xcodebuild \
    -workspace OmegaOS.xcworkspace \
    -scheme OmegaOS \
    -configuration Release \
    -derivedDataPath build \
    >> "$BUILD_LOG" 2>&1 || error "iOS build failed"

  IPA_PATH="build/Build/Products/Release-iphoneos/OmegaOS.ipa"
  if [ -f "$IPA_PATH" ]; then
    log "iOS build successful: $IPA_PATH"
    log "To deploy to TestFlight:"
    log "  xcrun altool --upload-app -f $IPA_PATH -t ios -u YOUR_APPLE_ID -p YOUR_APP_PASSWORD"
  else
    warn "IPA file not found at expected location"
  fi
}

build_android() {
  log "Building Android app..."

  if ! command -v gradle >/dev/null 2>&1 && [ ! -f "$REPO_ROOT/android/gradlew" ]; then
    error "Gradle not installed. Install Android SDK and build tools."
  fi

  cd "$REPO_ROOT/android"

  log "Building with Gradle..."
  ./gradlew assembleRelease >> "$BUILD_LOG" 2>&1 || error "Android build failed"

  APK_PATH="app/build/outputs/apk/release/app-release.apk"
  AAB_PATH="app/build/outputs/bundle/release/app-release.aab"

  if [ -f "$APK_PATH" ]; then
    log "Android APK build successful: $APK_PATH"
  fi

  if [ -f "$AAB_PATH" ]; then
    log "Android AAB build successful: $AAB_PATH"
    log "To deploy to Google Play:"
    log "  bundletool build-apks --bundle=$AAB_PATH --output=app.apks --ks=release.keystore --ks-pass=pass:KEYSTORE_PASSWORD"
  fi
}

case "$TARGET" in
  ios)
    build_ios
    ;;
  android)
    build_android
    ;;
  all)
    build_ios
    build_android
    ;;
  *)
    error "Unknown target: $TARGET. Use: ios, android, all"
    ;;
esac

log "Build completed successfully at $(date)"
log "Build log: $BUILD_LOG"
