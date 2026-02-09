#!/usr/bin/env bash
set -euo pipefail

xcodebuild build \
  -project JChat.xcodeproj \
  -scheme JChat \
  -destination 'platform=macOS' \
  -derivedDataPath ./DerivedData \
  CODE_SIGNING_ALLOWED=NO

xcodebuild test \
  -project JChat.xcodeproj \
  -scheme JChat \
  -destination 'platform=macOS' \
  -derivedDataPath ./DerivedData \
  -only-testing:JChatTests \
  CODE_SIGNING_ALLOWED=NO
