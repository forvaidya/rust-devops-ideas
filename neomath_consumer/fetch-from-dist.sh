#!/bin/bash
# Fetch neomath library from URL (file:// or http://)
# Usage: ./fetch-from-dist.sh https://dist.example.com/neomath
#        ./fetch-from-dist.sh file:///path/to/neomath/_dist

set -e

DIST_URL="${1:-file:///Users/maheshvaidya/neomath-lib/_dist}"

if [ -z "$DIST_URL" ]; then
    echo "Usage: $0 <dist-url>"
    echo "Examples:"
    echo "  $0 file:///Users/maheshvaidya/neomath-lib/_dist"
    echo "  $0 https://storage.example.com/neomath-lib"
    exit 1
fi

# Detect platform
if [[ $(uname -m) == "arm64" ]] || [[ $(uname -m) == "aarch64" ]]; then
    PLATFORM="arm64"
    TRIPLE="aarch64-apple-darwin"
else
    PLATFORM="intel"
    TRIPLE="x86_64-apple-darwin"
fi

DIST_DIR="./super-libs/neomath-ready-crates/$PLATFORM"

echo "Fetching neomath from: $DIST_URL/$PLATFORM"
echo "Platform: $PLATFORM ($TRIPLE)"

# Handle file:// URLs
if [[ "$DIST_URL" == file://* ]]; then
    SRC_PATH="${DIST_URL#file://}"
    if [ ! -d "$SRC_PATH/$PLATFORM" ]; then
        echo "Error: Distribution not found at $SRC_PATH/$PLATFORM"
        exit 1
    fi
    mkdir -p "$DIST_DIR"
    cp -r "$SRC_PATH/$PLATFORM"/* "$DIST_DIR/"
    echo "✓ Copied from local filesystem"

# Handle http(s):// URLs
elif [[ "$DIST_URL" == http* ]]; then
    mkdir -p "$DIST_DIR/lib" "$DIST_DIR/docs"

    # Download metadata
    curl -s "$DIST_URL/$PLATFORM/metadata.json" -o "$DIST_DIR/metadata.json"
    [ $? -eq 0 ] || { echo "Error: Failed to download metadata"; exit 1; }

    # Download .rlib and .rmeta files
    echo "Downloading libraries..."
    LIBS=$(jq -r '.lib_files[]' "$DIST_DIR/metadata.json" 2>/dev/null | xargs -n1 basename)

    for lib in $LIBS; do
        echo "  Downloading $lib..."
        curl -s "$DIST_URL/$PLATFORM/lib/$lib" -o "$DIST_DIR/lib/$lib"
    done
    echo "✓ Downloaded from remote"
else
    echo "Error: Unknown URL scheme. Use file:// or http(s)://"
    exit 1
fi

# Create .cargo/config.toml
mkdir -p .cargo
cat > .cargo/config.toml <<EOF
[build]
rustflags = ["-L", "dependency=$(cd "$DIST_DIR" && pwd)/lib"]
EOF

echo "✓ Configured rustflags in .cargo/config.toml"

# Show metadata
echo ""
echo "Distribution Info:"
cat "$DIST_DIR/metadata.json" | jq '.' 2>/dev/null || cat "$DIST_DIR/metadata.json"
