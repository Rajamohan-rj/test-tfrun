# tfrun - Git-aware Terraform Runner

A tool to run Terraform commands on files changed in git, making Terraform workflows more efficient in large codebases.

## Features

- 🚀 Only runs Terraform on modules with actual changes
- 🔍 Multiple git comparison strategies (staged, against ref, all files)
- 🧪 Dry-run support for safe testing
- 🔄 Smart `terraform init` detection and execution
- 📝 Verbose logging for debugging

## Installation

### 🚀 Quick Install (Recommended)

#### Unix/Linux/macOS
```bash
curl -sSL https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.sh | bash
```

#### Windows (PowerShell)
```powershell
iwr -useb https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.ps1 | iex
```

### 📦 Package Managers

#### Using Go
```bash
go install github.com/rajamohan-rj/tfrun@latest
```

#### Using Homebrew (macOS/Linux)
```bash
# Add the tap (after setting up Homebrew tap)
brew tap rajamohan-rj/tap
brew install tfrun
```

### 🛠️ Advanced Installation

#### Install to custom directory
```bash
# Unix/Linux/macOS
curl -sSL https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.sh | bash -s -- --dir ~/.local/bin

# Windows
iwr -useb https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.ps1 | iex -InstallDir 'C:\tools'
```

#### Install specific version
```bash
# Unix/Linux/macOS
curl -sSL https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.sh | bash -s -- --version v1.0.5

# Windows
iwr -useb https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.ps1 | iex -Version 'v1.0.5'
```

### 📥 Manual Download

Download the latest binary from [releases](https://github.com/rajamohan-rj/tfrun/releases) and extract:
Download the latest binary from [releases](https://github.com/rajamohan-rj/tfrun/releases).

## Usage

```bash
# Run on staged changes
tfrun --staged

# Compare against main branch
tfrun --against main

# Dry run to see what would happen
tfrun --dry-run --verbose

# Force init on all modules
tfrun --all --force-init
```

## Options

- `--staged` - Use staged changes (`git diff --cached`)
- `--against <ref>` - Compare against a git ref
- `--all` - Consider all tracked .tf files
- `--force-init` - Always run terraform init
- `--no-upgrade` - Skip upgrade during init
- `--dry-run` - Print actions without executing
- `--verbose` - Verbose logging

## License

MIT License - see [LICENSE](LICENSE) file for details.
