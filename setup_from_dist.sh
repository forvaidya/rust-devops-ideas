#!/bin/bash
# Setup consumer project to use distributed neomath library

set -e

CRATE_NAME="neomath"
DIST_SOURCE="${1:-./_dist}"

# Detect local platform
if [[ $(uname -m) == "arm64" ]] || [[ $(uname -m) == "aarch64" ]]; then
    PLATFORM="arm64"
else
    PLATFORM="intel"
fi

DIST_PATH="$DIST_SOURCE/$PLATFORM"

if [ ! -d "$DIST_PATH" ]; then
    echo "Error: Distribution not found at $DIST_PATH"
    exit 1
fi

echo "Setting up $CRATE_NAME consumer for $PLATFORM..."

# Create .cargo config to point to distributed library
mkdir -p .cargo
cat > .cargo/config.toml <<'EOF'
[build]
rustflags = ["-L", "dependency=../neomath/_dist/PLATFORM_PLACEHOLDER/lib"]
EOF

sed -i '' "s|PLATFORM_PLACEHOLDER|$PLATFORM|g" .cargo/config.toml

# Create Cargo.toml snippet instructions
cat > INTEGRATION.md <<EOF
# Integration Guide for $CRATE_NAME

## Setup
The library is distributed pre-built for your platform ($PLATFORM).

## Using in Your Project
Add this to your \`Cargo.toml\`:

\`\`\`toml
[$CRATE_NAME]
path = "../path/to/$CRATE_NAME/_dist/$PLATFORM"
\`\`\`

## File Structure
- **lib/**: Pre-compiled .rlib and .rmeta files
- **docs/api/**: Complete API documentation (open \`docs/api/neomath/index.html\`)
- **metadata.json**: Build info and library manifest

## Import in Your Code
\`\`\`rust
use $CRATE_NAME::arithmetic::{add_integers, add_floats};

fn main() {
    let result = add_integers("5", "3").unwrap();
    println!("5 + 3 = {}", result);
}
\`\`\`

## Documentation
Open \`../$DIST_SOURCE/$PLATFORM/docs/api/neomath/index.html\` in your browser.

## Platform Info
\`\`\`json
$(cat "$DIST_PATH/metadata.json")
\`\`\`
EOF

echo "✓ Consumer setup complete!"
echo "✓ Read INTEGRATION.md for usage instructions"
echo "✓ API docs: file://$DIST_PATH/docs/api/neomath/index.html"
