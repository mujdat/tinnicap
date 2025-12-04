#!/bin/bash

# Release script for TinniCap macOS app
# Creates a distributable zip file ready for GitHub releases

set -e

# Get version from argument or default to "dev"
VERSION=${1:-dev}

echo "🔨 Building TinniCap v${VERSION}..."
echo ""

# Build the app
xcodebuild \
  -project TinniCap.xcodeproj \
  -scheme TinniCap \
  -configuration Release \
  -derivedDataPath ./build \
  clean build

echo ""
echo "📦 Creating release package..."

# Create releases directory
mkdir -p releases

# Zip the app
cd build/Build/Products/Release
zip -r -q ../../../../releases/TinniCap-${VERSION}.zip TinniCap.app
cd ../../../../

echo ""
echo "✅ Release package created!"
echo ""
echo "📍 Location: ./releases/TinniCap-${VERSION}.zip"
echo "📊 Size: $(du -h releases/TinniCap-${VERSION}.zip | cut -f1)"
echo ""
echo "Next steps:"
echo "  1. Test the app: unzip releases/TinniCap-${VERSION}.zip && open TinniCap.app"
echo "  2. Create a git tag: git tag -a v${VERSION} -m 'Release v${VERSION}'"
echo "  3. Push the tag: git push origin v${VERSION}"
echo "  4. Upload releases/TinniCap-${VERSION}.zip to GitHub release"
echo ""
