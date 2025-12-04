#!/bin/bash

# Build script for TinniCap macOS app

set -e

echo "Building TinniCap..."

xcodebuild \
  -project TinniCap.xcodeproj \
  -scheme TinniCap \
  -configuration Release \
  -derivedDataPath ./build \
  clean build

echo ""
echo "Build complete!"
echo "App location: ./build/Build/Products/Release/TinniCap.app"
echo ""
echo "To run the app:"
echo "  open ./build/Build/Products/Release/TinniCap.app"
echo ""
echo "To copy to Applications folder:"
echo "  cp -r ./build/Build/Products/Release/TinniCap.app /Applications/"
