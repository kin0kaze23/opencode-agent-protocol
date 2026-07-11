---
name: rust
description: Rust development for example-cli and CLI tools
---

# Rust Skill

Rust development guide for example-cli and other Rust projects.

## Procedure

Before writing Rust code, read the following:

1. Read the project's `Cargo.toml` to understand dependencies and edition
2. Read the `src/lib.rs` or `src/main.rs` entry point to understand the module structure
3. Read 1-2 existing modules to match the project's error handling and logging patterns
4. Read the `tests/` directory to understand the testing conventions used

Then follow these patterns:

---

## Project Using Rust

| Project | Purpose |
|---------|---------|
| example-cli | Personal AI assistant |

## Setup

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Update
rustup update

# IDE support
rust-analyzer (VS Code)
```

## Project Structure

```
ironclaw/
├── src/
│   ├── main.rs        # Entry point
│   ├── lib.rs         # Library root
│   ├── cli.rs         # CLI argument parsing
│   ├── config.rs      # Configuration
│   ├── ai.rs          # AI integration
│   └── commands/      # Command modules
├── tests/             # Integration tests
├── Cargo.toml         # Dependencies
├── Cargo.lock         # Locked versions
└── .env               # Environment (gitignored)
```

## Key Patterns

### CLI with Clap
```rust
use clap::{Parser, Subcommand}

#[derive(Parser)]
#[command(name = "ironclaw")]
#[command(about = "Personal AI Assistant")]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    #[arg(short, long, default_value = "false")]
    verbose: bool,
}

#[derive(Subcommand)]
enum Commands {
    /// Start the AI assistant
    Run {
        #[arg(short, long)]
        prompt: Option<String>,
    },
    /// Configure settings
    Config {
        #[arg(short, long)]
        key: String,
        #[arg(short, long)]
        value: String,
    },
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Commands::Run { prompt } => run(prompt),
        Commands::Config { key, value } => configure(key, value),
    }
}
```

### Async with Tokio
```rust
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let response = fetch_data().await?;
    println!("{}", response);
    Ok(())
}

async fn fetch_data() -> Result<String, reqwest::Error> {
    reqwest::get("https://api.example.com/data")
        .await?
        .text()
        .await
}
```

### Error Handling
```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum example-cliError {
    #[error("Configuration error: {0}")]
    Config(#[from] config::ConfigError),

    #[error("API error: {0}")]
    Api(#[from] reqwest::Error),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

pub type Result<T> = std::result::Result<T, example-cliError>;
```

### Logging
```rust
use tracing::{info, error, warn};

fn main() {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();

    info!("Starting example-cli");

    if let Err(e) = run() {
        error!("Error: {}", e);
        std::process::exit(1);
    }
}
```

## Dependencies (Cargo.toml)

```toml
[package]
name = "ironclaw"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1", features = ["full"] }
reqwest = { version = "0.11", features = ["json"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
clap = { version = "4", features = ["derive"] }
thiserror = "1"
tracing = "0.1"
tracing-subscriber = "0.3"
dotenv = "0.15"

[dev-dependencies]
mockall = "0.11"
tokio-test = "0.4"
```

## Testing

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_something() {
        assert_eq!(2 + 2, 4);
    }

    #[tokio::test]
    async fn test_async_function() {
        let result = async_calculate().await;
        assert!(result.is_ok());
    }
}
```

```bash
# Run tests
cargo test

# Test with coverage
cargo tarpaulin

# Run specific test
cargo test test_name
```

## Building

```bash
# Development
cargo build

# Release (optimized)
cargo build --release

# Check without building
cargo check

# Format
cargo fmt

# Lint
cargo clippy

# Update dependencies
cargo update
```

## Best Practices

1. **Use Result types** - No exceptions, use `?` operator
2. **Leverage the type system** - Newtypes, enums
3. **Write tests** - Unit + integration
4. **Use Clippy** - Catch common mistakes
5. **Profile release builds** - `cargo bench`
6. **Document public APIs** - `/// Doc comments`

## Key Crates for Your Stack

| Use Case | Crate |
|----------|-------|
| CLI | clap |
| HTTP client | reqwest |
| Async runtime | tokio |
| Serialization | serde |
| Error handling | thiserror |
| Config | config |
| Logging | tracing |
| Async HTTP | axum (web server) |

## Output format

Produce a Rust development report in this exact format:

```
## Rust Development — <module/feature name>

**Crate:** <crate or module affected>
**Pattern:** <CLI / async / error handling / testing / etc>

### Changes
- <file>: <what was added or modified>

### Verification
- [ ] `cargo check` passes
- [ ] `cargo clippy` passes
- [ ] `cargo test` passes
- [ ] `cargo fmt` applied
```

## Out of Scope

This skill does NOT:
- Write non-Rust code (use the appropriate language skill)
- Replace security auditing for production Rust code (use sec-codeql)
- Fix compiler errors that require architectural changes (that is /debug)
- Generate project scaffolding from scratch (use cargo new)
- Audit Solana programs (use sec-solana for Solana-specific security)