# NeoMath Project Conventions

Established patterns for library development and distribution.

## Library Structure

```
neomath-lib/
├── src/
│   ├── lib.rs          # Single line: pub mod arithmetic;
│   └── arithmetic.rs   # Functions with Result<T, String> error handling
├── examples/
│   ├── main.rs         # __main__ equivalent (default entry point)
│   ├── demo.rs         # Demo mode with hardcoded test cases
│   └── cli.rs          # CLI tool accepting args
├── distribute.sh       # Cross-platform builder (arm64 + intel)
└── run                 # Bash wrapper for convenient invocation
```

## Consumer Structure

```
neomath_consumer/
├── src/main.rs
├── Cargo.toml          # path = "neomath-lib" for metadata only
├── fetch-from-dist.sh  # Download binaries from distribution URL
├── super-libs/         # Distribution folder (gitignored, flexible naming)
└── .gitignore
```

## Error Handling

- All public functions return `Result<T, String>`
- Validate inputs at function boundary (no unwrap)
- Descriptive error messages: "Invalid integer input", "Invalid float input"
- No silent failures

## Documentation

- Doc comments on all public items (`/// `)
- Include examples in doc comments
- See `cargo doc --open` for full API

## Distribution

1. **Build**: `./distribute.sh` → creates platform directories (arm64/, intel/)
2. **Contents per platform**:
   - `lib/` — .rlib, .rmeta binaries
   - `docs/api/` — HTML documentation
   - `examples/` — Source code + run wrapper
   - `metadata.json` — Version, platform, build timestamp

3. **Fetch**: `./fetch-from-dist.sh <URL>` supports:
   - `file://./super-libs/neomath-ready-crates` (local)
   - `https://s3.example.com/neomath/v0.1.0` (S3/HTTP)
   - Auto-detects platform (arm64/intel)

4. **Gitignore patterns**:
   - `/target/` — build artifacts
   - `Cargo.lock` — lock file
   - `super-libs/` or any distribution folder — external binaries
   - `.cargo/config.toml` — generated rustflags
   - `.neomath_dist/` — fetch cache

## Distribution Folder Naming

- **Flexible**: Name can be `external-libs`, `super-libs`, `deps`, etc.
- **Fixed**: Internal recursive structure (arm64/, intel/, lib/, docs/, examples/, metadata.json) must be preserved
- **Location**: Inside consumer project for self-contained distribution

## Testing

```bash
cargo test          # All tests pass
cargo build         # No warnings
cargo doc --open    # API docs render
```

## Separate Lifecycles

- **Library team** (`neomath-lib/`): Source, build tools, distribute.sh
- **Consumer team** (`neomath_consumer/`): No source, fetches pre-built binaries, tests via fetch-from-dist.sh

Source code never distributed to consumer — only .rlib/.rmeta binaries and documentation.

## Example Usage

```bash
# Library: build and distribute
cd neomath-lib
./distribute.sh

# Consumer: fetch and run
cd neomath_consumer
./fetch-from-dist.sh file://./super-libs/neomath-ready-crates
cargo run
```

## Key Decisions

- **rlib format**: Best for Rust-to-Rust consumption, source-free distribution
- **Result types**: Forces explicit error handling at call sites
- **Module separation**: Keeps lib.rs simple, groups related functions
- **Examples in project**: Distributed with library, demonstrates API to consumers
- **Separate Cargo homes**: Test isolation via `CARGO_HOME=~/.trial1` pattern
