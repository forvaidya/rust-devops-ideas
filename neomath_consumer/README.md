# NeoMath Consumer

Consumer application that uses the **pre-built** NeoMath library from a remote distribution.

## Setup

### 1. Fetch Library from Distribution

```bash
# From local filesystem (file:// URL)
./fetch-from-dist.sh file:///Users/maheshvaidya/neomath-lib/_dist

# From HTTP server
./fetch-from-dist.sh https://storage.example.com/neomath
```

This:
- Detects your platform (arm64 or intel)
- Downloads library binaries (`.rlib`, `.rmeta`)
- Downloads API documentation
- Configures `.cargo/config.toml` with rustflags

### 2. Build & Run

```bash
cargo build
cargo run
```

## Project Lifecycle

- **NeoMath Library** (`neomath-lib/`) — Built separately, distributed as binaries
- **NeoMath Consumer** (`neomath-consumer/`) — Fetches pre-built library, uses it

They are **completely independent** git repositories.

## Distribution Sources

Supports multiple distribution methods:

| Method | URL | Example |
|--------|-----|---------|
| Local FS | `file://` | `file:///path/to/neomath-lib/_dist` |
| HTTP | `http://` | `http://dist.example.com/neomath` |
| HTTPS | `https://` | `https://s3.example.com/releases/neomath` |
| S3 | `s3://` | (via S3 HTTP endpoint) |

## Library Files

After `fetch-from-dist.sh`:

```
.neomath_dist/
├── arm64/          (or intel/)
│   ├── lib/        # .rlib + .rmeta binaries
│   ├── docs/       # API documentation (HTML)
│   └── metadata.json
```

Open docs in browser:
```bash
open .neomath_dist/arm64/docs/api/neomath/index.html
```

## Source Code

The NeoMath source is **not** included in this distribution.  
Only pre-compiled binaries are provided.

See `neomath-lib/` for the source (separate repo).
