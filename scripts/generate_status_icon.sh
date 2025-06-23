#!/bin/bash

# Generate a small status bar icon for macOS system tray

BASE_IMAGE="assets/logo.png"

resize_sips() {
  sips -Z "$2" "$1" --out "$3"
}

generate_status_icon() {
  echo "🍏 Generating macOS status bar icon..."
  local STATUS_OUT="macos/Runner/Assets.xcassets/StatusIcon.imageset"
  mkdir -p "$STATUS_OUT"

  # Only a single 16x16 icon is required
  resize_sips "$BASE_IMAGE" 16 "$STATUS_OUT/icon.png"

  cat > "$STATUS_OUT/Contents.json" <<EOF
{
  "images": [
    {
      "idiom": "mac",
      "filename": "icon.png",
      "scale": "1x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
EOF
}

### --- Run ---
generate_status_icon

