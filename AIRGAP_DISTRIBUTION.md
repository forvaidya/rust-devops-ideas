# Airgapped Distribution Model

Complete guide for building and distributing Rust software in isolated networks with zero external dependencies.

## Overview

Two complementary distribution strategies:

1. **Binary Distribution** — Pre-compiled library binaries (source-free)
2. **Crates Mirror** — Local copy of crates.io dependencies

Combined: Airgapped systems build completely offline.

---

## Part 1: Binary Distribution Model

### Problem Solved
- Library source code confidential (never leave team)
- Consumers build without library source code
- Works offline after initial fetch

### Architecture

```
Library Team (neomath-lib)
├─ Source code (confidential)
├─ Build: cargo build --release
├─ Compile to binaries: .rlib, .rmeta
├─ Generate docs: cargo doc
└─ Distribute: arm64/ + intel/ + metadata.json

                    ↓ (file://, https://, S3)
                    
Distribution Server
├─ /neomath/
│  ├─ arm64/
│  │  ├─ lib/           (.rlib, .rmeta files)
│  │  ├─ docs/api/      (HTML documentation)
│  │  ├─ examples/      (usage examples)
│  │  └─ metadata.json
│  └─ intel/
│     ├─ lib/
│     ├─ docs/api/
│     ├─ examples/
│     └─ metadata.json

                    ↓ (fetch-from-dist.sh)
                    
Consumer Team (neomath-consumer)
├─ No source code access
├─ Pre-built binaries in ./super-libs/
├─ Cargo configured with rustflags
└─ cargo build → links against .rlib (no compilation)
```

### Setup: Library Team

**1. Build for distribution**
```bash
cd neomath-lib
./distribute.sh
# Creates _dist/ with arm64/ and intel/ subdirectories
```

**2. Upload to distribution server**
```bash
# Option A: Local filesystem
cp -r _dist /path/to/distribution-server/neomath/

# Option B: S3
S3_BUCKET="company-releases" ./distribute.sh

# Option C: HTTP server
scp -r _dist user@dist.server:/var/www/neomath/
```

**3. Announce distribution URL**
```
file:///local/path/to/neomath/_dist
https://dist.company.com/neomath
s3://company-releases/neomath/v0.1.0
```

### Setup: Consumer Team

**1. Fetch pre-built binaries**
```bash
cd neomath-consumer
./fetch-from-dist.sh https://dist.company.com/neomath
# Downloads into ./super-libs/neomath-ready-crates/
# Configures .cargo/config.toml with rustflags
```

**2. Build and run**
```bash
cargo build
cargo run
# Builds against pre-compiled binaries
# NO library source code needed
# NO compilation of library code
```

### Key Properties

| Aspect | Benefit |
|--------|---------|
| **Source Confidentiality** | Source never distributed, only binaries |
| **Faster Builds** | No library compilation (pre-compiled .rlib) |
| **Offline Build** | Works after fetch (no network during cargo build) |
| **Smaller Downloads** | Only binaries + docs, not full source |
| **IP Protection** | Library logic stays confidential |
| **Team Separation** | Library team ≠ Consumer team |

### File Structure

```
neomath-consumer/
├── super-libs/              # Downloaded distribution
│   └── neomath-ready-crates/
│       ├── arm64/
│       │   ├── lib/         # .rlib, .rmeta binaries
│       │   ├── docs/api/    # API documentation
│       │   ├── examples/    # Usage examples
│       │   └── metadata.json
│       └── intel/
├── src/main.rs              # Consumer code
├── Cargo.toml               # Declares neomath dependency
├── .cargo/config.toml       # Rustflags pointing to super-libs/
└── .gitignore               # super-libs/ ignored
```

---

## Part 2: Crates.io Mirror

### Problem Solved
- Airgapped systems can't reach crates.io
- Need local copy of Rust dependencies
- Build completely offline without internet

### Architecture

```
Distribution Server (has internet egress)
├─ Cron job (daily): cargo-local-registry --sync
├─ Pulls all dependencies from crates.io
├─ Stores in /var/cache/crates-mirror/
└─ Exposes via HTTP: http://dist-server:8000

                    ↓ (configure as registry)
                    
Consumer Machines (NO internet access)
├─ .cargo/config.toml:
│   [source.crates-io]
│   replace-with = "internal-mirror"
│   [source.internal-mirror]
│   registry = "http://dist-server:8000"
├─ cargo build
└─ ✓ Fetches ALL deps from internal mirror (offline)
```

### Setup: Distribution Server

**1. Install mirror tool**
```bash
cargo install cargo-local-registry
```

**2. Create cron job**
```bash
# /usr/local/bin/sync-crates-mirror.sh
#!/bin/bash
set -e

MIRROR_DIR="/var/cache/crates-mirror"
mkdir -p "$MIRROR_DIR"

# Sync all crates from crates.io
cargo-local-registry --sync "$MIRROR_DIR"

# Start HTTP server (or use existing web server)
# http://dist-server:8000
```

**3. Schedule sync**
```bash
# Crontab: sync every 6 hours
0 */6 * * * /usr/local/bin/sync-crates-mirror.sh
```

**4. Expose via HTTP**
```bash
# Option A: Python (simple)
python3 -m http.server 8000 --directory /var/cache/crates-mirror

# Option B: Nginx (production)
# Serve /var/cache/crates-mirror on port 80
```

### Setup: Consumer Machines

**1. Configure Cargo**
```toml
# ~/.cargo/config.toml (or .cargo/config.toml in project)
[source.crates-io]
replace-with = "internal-mirror"

[source.internal-mirror]
registry = "http://dist-server:8000"
```

**2. Build offline**
```bash
cargo build
# All dependencies fetched from internal mirror
# No internet needed
# No need for crates.io access
```

### Alternative: Artifactory / Nexus

For enterprise environments:

**Artifactory (JFrog)** — Commercial, Production-Grade
```
https://dist.company.com/artifactory/api/cargo/crates-io
```
- Automatic sync from crates.io
- Access control, audit logs
- Single URL for all consumers
- Supports binary distribution + crates mirror
- Official Rust support: https://jfrog.com/learn/devops/how-to-run-a-private-cargo-registry/

**Nexus Repository**
```
https://dist.company.com/repository/crates/
```
- Automatic sync from crates.io
- Proxy + cache pattern
- Storage optimization

Configuration remains the same:
```toml
[source.crates-io]
replace-with = "company-registry"

[source.company-registry]
registry = "https://dist.company.com/repository/crates/"
```

---

## Part 3: Combined Approach (Complete Airgap)

### Architecture

```
Distribution Server (Internet Access)
├─ Cron 1: cargo-local-registry --sync → /crates-mirror/
│          (pulls all crates.io dependencies)
├─ Cron 2: ./distribute.sh → /neomath/
│          (builds neomath binaries from source)
└─ HTTP Server on port 8000
   ├─ /crates/        (crates.io mirror)
   └─ /neomath/       (binary distribution)

                    ↓ One-time initial fetch
                    
Airgapped Network (NO Internet)
└─ Consumer Machines
   ├─ .cargo/config.toml:
   │  [source.crates-io]
   │  replace-with = "internal"
   │  [source.internal]
   │  registry = "http://dist-server:8000/crates/"
   ├─ fetch-from-dist.sh http://dist-server:8000/neomath/
   │  → downloads super-libs/
   ├─ cargo build
   └─ cargo run
   ✓ Complete offline build + run (ZERO external access)
```

### Complete Setup

**Distribution Server**
```bash
# 1. Setup mirror
cargo install cargo-local-registry
mkdir -p /var/dist/crates /var/dist/neomath

# 2. Sync crates.io mirror
cargo-local-registry --sync /var/dist/crates

# 3. Build library binaries
cd /path/to/neomath-lib
./distribute.sh DIST_DIR=/var/dist/neomath

# 4. Run HTTP server
cd /var/dist
python3 -m http.server 8000
# Now accessible:
# - http://dist-server:8000/crates/
# - http://dist-server:8000/neomath/
```

**Airgapped Consumer**
```bash
# 1. Configure Cargo for internal mirror
cat > ~/.cargo/config.toml <<'EOF'
[source.crates-io]
replace-with = "internal"

[source.internal]
registry = "http://dist-server:8000/crates/"
EOF

# 2. Project-level setup
cd neomath-consumer

# 3. Fetch binary distribution
./fetch-from-dist.sh http://dist-server:8000/neomath/

# 4. Build completely offline
cargo build
cargo run
```

### Workflow

**Initial Setup (One-time)**
1. Distribution server syncs all crates.io → /crates/
2. Distribution server builds neomath → /neomath/
3. Consumers do initial fetch from distribution server

**Daily Usage (Airgapped)**
1. Consumers have everything locally
2. Zero network access needed
3. Build, test, deploy completely offline
4. No external dependencies

### Update Cycle

When library updates:
```bash
# Distribution server (has internet)
cd neomath-lib
git pull origin
./distribute.sh DIST_DIR=/var/dist/neomath
# New binaries available at http://dist-server:8000/neomath/

# Consumer (airgapped) updates
./fetch-from-dist.sh http://dist-server:8000/neomath/
cargo build  # Uses new binaries
```

When dependencies update:
```bash
# Distribution server syncs new crates.io versions
/usr/local/bin/sync-crates-mirror.sh
# Automatically runs via cron

# Consumers don't need to do anything
# Next cargo build fetches latest versions
```

---

## Part 4: Security & Verification

### Binary Verification

**Before consuming fetched binaries:**
```bash
# Verify file format (ARM64)
file super-libs/neomath-ready-crates/arm64/lib/*.rlib
# Should output: "current ar archive"

# Check symbols (ensure it's the right code)
nm super-libs/neomath-ready-crates/arm64/lib/*.rlib | grep add_integers
# Should show: add_integers symbol present
```

### Metadata Validation

Each distribution includes `metadata.json`:
```json
{
  "name": "neomath",
  "version": "0.1.0",
  "platform": "arm64",
  "built": "2026-06-28T04:07:48Z"
}
```

Verify before using:
```bash
cat super-libs/neomath-ready-crates/arm64/metadata.json | jq .
```

### Checksums

For S3/HTTP distribution, add checksums:
```bash
# Generate checksums
sha256sum _dist/arm64/lib/*.rlib > _dist/arm64/CHECKSUMS

# Verify after download
sha256sum -c _dist/arm64/CHECKSUMS
```

---

## Part 5: Troubleshooting

### Consumer: "Can't fetch from distribution"

Check distribution URL:
```bash
curl -I http://dist-server:8000/neomath/arm64/metadata.json
# Should return HTTP 200

curl http://dist-server:8000/neomath/arm64/metadata.json | jq .
# Should show metadata
```

### Consumer: "Registry not found"

Check Cargo config:
```bash
cat .cargo/config.toml
# Should show correct registry URL

# Test registry access
curl -I http://dist-server:8000/crates/config.json
# Should return HTTP 200
```

### Consumer: "Dependency not in mirror"

Sync mirror on distribution server:
```bash
/usr/local/bin/sync-crates-mirror.sh
# Re-sync all crates from crates.io
```

### Build fails: "Can't find library"

Check rustflags:
```bash
cat .cargo/config.toml
# Should have: rustflags = ["-L", "dependency=./super-libs/..."]

# Verify binaries exist
ls -la super-libs/neomath-ready-crates/arm64/lib/
# Should list .rlib and .rmeta files
```

---

## Reference: Commands

### Distribution Server

```bash
# Initial setup
cargo install cargo-local-registry
mkdir -p /var/dist/{crates,neomath}

# Sync crates.io mirror (run daily via cron)
cargo-local-registry --sync /var/dist/crates

# Build library distribution
cd /path/to/neomath-lib
./distribute.sh DIST_DIR=/var/dist/neomath

# Serve via HTTP
cd /var/dist
python3 -m http.server 8000
```

### Consumer Setup (Airgapped)

```bash
# Configure Cargo
mkdir -p ~/.cargo
cat > ~/.cargo/config.toml <<EOF
[source.crates-io]
replace-with = "internal"

[source.internal]
registry = "http://dist-server:8000/crates/"
EOF

# Fetch library binaries
cd ~/projects/neomath-consumer
./fetch-from-dist.sh http://dist-server:8000/neomath/

# Build offline
cargo build
cargo run
```

### Update & Maintain

```bash
# Distribution server: update library
cd /path/to/neomath-lib
git pull
./distribute.sh DIST_DIR=/var/dist/neomath

# Distribution server: sync dependencies
cargo-local-registry --sync /var/dist/crates

# Consumer: fetch updated binaries
./fetch-from-dist.sh http://dist-server:8000/neomath/
cargo build  # Uses updated binaries
```

---

## ⚠️ CAUTION: Internal Crates Should Use Full Builds

**For internal teams developing together, full source builds are superior:**

### When to use Pre-Compiled Binaries (Binary Distribution)
- **External distribution** → Third-party consumers, partners, vendors
- **Source confidentiality required** → Proprietary code, trade secrets
- **Distribution-only teams** → No development access needed
- **Fast CI/CD** → Pre-compiled artifacts, minimal compile time

### When to use Full Source Builds (Recommended for Internal)
- **Internal development** → Multiple teams working on same codebase ✓
- **Debugging** → Need to step through library source code
- **Modifications** → Bug fixes, features in library, test changes
- **Verification** → Audit build process, ensure source matches binaries
- **Cargo workspace** → Natural Rust multi-crate development pattern

**Internal Development Pattern:**
```bash
# Better for internal teams
[dependencies]
neomath = { path = "../neomath-lib" }  # Source access
# OR
[workspace]
members = ["neomath-lib", "neomath-consumer"]
```

**External Distribution Pattern:**
```bash
# Use pre-compiled binaries for external consumers
./fetch-from-dist.sh https://releases.company.com/neomath/
```

**Recommendation:**
- **Within company**: Use source builds (cargo workspace)
- **Outside company**: Use binary distribution (pre-compiled)
- **Airgap requirement**: Use binary distribution + crates mirror

## Key Takeaways

✓ **Binary Distribution** → Pre-compiled binaries for external distribution, source confidential, fast builds  
✓ **Crates Mirror** → Local copy of dependencies, offline builds  
✓ **Combined** → Complete airgap with zero external access  
✓ **Scalable** → Works for 1 team or 1000 teams  
✓ **Enterprise-ready** → Security, offline, controlled distribution  
⚠️ **Internal teams** → Use full source builds + workspace (better for development)  

This model powers enterprise Rust deployments in:
- Classified/secure networks
- Airgapped data centers
- Regulated environments (healthcare, finance, government)
- Supply chain security
