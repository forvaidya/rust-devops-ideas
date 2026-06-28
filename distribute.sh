#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRATE_NAME="neomath"
VERSION=$(grep '^version' "$SCRIPT_DIR/neomath/Cargo.toml" | head -1 | cut -d'"' -f2)
DIST_DIR="${DIST_DIR:-$SCRIPT_DIR/_dist}"
S3_BUCKET="${S3_BUCKET:-}"

# Detect platform
if [[ $(uname -m) == "arm64" ]] || [[ $(uname -m) == "aarch64" ]]; then
    PLATFORM="arm64"
    TRIPLE="aarch64-apple-darwin"
else
    PLATFORM="intel"
    TRIPLE="x86_64-apple-darwin"
fi

echo "Building $CRATE_NAME v$VERSION for $PLATFORM..."

# Build for current platform
cd "$SCRIPT_DIR/neomath"
cargo build --release
cargo doc --no-deps --release

# Setup dist directories
mkdir -p "$DIST_DIR/$PLATFORM"/{lib,docs}

# Copy libraries
find target/release/deps -name "lib${CRATE_NAME}*.rlib" -exec cp {} "$DIST_DIR/$PLATFORM/lib/" \;
find target/release/deps -name "lib${CRATE_NAME}*.rmeta" -exec cp {} "$DIST_DIR/$PLATFORM/lib/" \;
find target/release/deps -name "lib${CRATE_NAME}*.so" 2>/dev/null -exec cp {} "$DIST_DIR/$PLATFORM/lib/" \; || true

# Copy documentation
cp -r target/doc "$DIST_DIR/$PLATFORM/docs/api"

# Create metadata
cat > "$DIST_DIR/$PLATFORM/metadata.json" <<EOF
{
  "name": "$CRATE_NAME",
  "version": "$VERSION",
  "platform": "$PLATFORM",
  "triple": "$TRIPLE",
  "built": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "crate_type": "rlib",
  "lib_files": $(find "$DIST_DIR/$PLATFORM/lib" -type f -name "*.rlib" -o -name "*.rmeta" | jq -R . | jq -s .)
}
EOF

echo "✓ Packaged for $PLATFORM:"
echo "  Library: $DIST_DIR/$PLATFORM/lib"
echo "  Docs: $DIST_DIR/$PLATFORM/docs/api"
echo "  Metadata: $DIST_DIR/$PLATFORM/metadata.json"
ls -lh "$DIST_DIR/$PLATFORM/lib/"

# Upload to S3 if configured
if [ -n "$S3_BUCKET" ]; then
    echo "Uploading to S3..."
    aws s3 sync "$DIST_DIR/$PLATFORM" "s3://$S3_BUCKET/$CRATE_NAME/v$VERSION/$PLATFORM/" \
        --exclude ".git*" --exclude "target/*"
    echo "✓ Uploaded to s3://$S3_BUCKET/$CRATE_NAME/v$VERSION/$PLATFORM/"
fi
