#!/bin/bash

# Script to test GoReleaser configuration locally

set -e

echo "🔍 Checking GoReleaser configuration..."
goreleaser check

echo "🧪 Testing local build..."
goreleaser build --single-target --snapshot --clean

echo "✅ Local test completed successfully!"
echo "📦 Built artifacts:"
ls -la dist/

echo "🚀 Testing built binary:"
BINARY=$(find dist -name "tfrun" -type f | head -1)
if [ -n "$BINARY" ]; then
    echo "Binary: $BINARY"
    $BINARY --version
    $BINARY --help
else
    echo "❌ No binary found!"
    exit 1
fi

echo "✨ All tests passed! Ready for release."
