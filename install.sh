#!/bin/bash

# tfrun installer script
#!/bin/bash
# tfrun installer script
# 
# Usage: curl -sSL https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.sh | bash

set -e

# Default values
INSTALL_DIR="/usr/local/bin"
REPO="rajamohan-rj/tfrun"
BINARY_NAME="tfrun"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        -h|--help)
            echo "tfrun installer"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --dir DIR      Install directory (default: /usr/local/bin)"
            echo "  --version VER  Specific version to install (default: latest)"
            echo "  --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  # Install to default location"
            echo "  curl -sSL https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.sh | bash"
            echo ""
            echo "  # Install to custom directory"
            echo "  curl -sSL https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.sh | bash -s -- --dir ~/.local/bin"
            echo ""
            echo "  # Install specific version"
            echo "  curl -sSL https://raw.githubusercontent.com/rajamohan-rj/tfrun/main/install.sh | bash -s -- --version v1.0.5"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS and architecture
detect_platform() {
    local os=""
    local arch=""
    
    case "$(uname -s)" in
        Darwin)
            os="Darwin"
            ;;
        Linux)
            os="Linux"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            os="Windows"
            ;;
        *)
            print_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
    
    case "$(uname -m)" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        arm64|aarch64)
            arch="arm64"
            ;;
        *)
            print_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
    
    echo "${os}_${arch}"
}

# Get latest release version
get_latest_version() {
    local api_url="https://api.github.com/repos/${REPO}/releases/latest"
    local latest_version
    
    if command -v curl > /dev/null 2>&1; then
        latest_version=$(curl -s "$api_url" | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    elif command -v wget > /dev/null 2>&1; then
        latest_version=$(wget -qO- "$api_url" | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    else
        print_error "curl or wget is required"
        exit 1
    fi
    
    if [ -z "$latest_version" ]; then
        print_error "Failed to get latest version"
        exit 1
    fi
    
    echo "$latest_version"
}

# Download and install
install_tfrun() {
    print_status "Installing tfrun..."
    
    # Detect platform
    local platform=$(detect_platform)
    print_status "Detected platform: $platform"
    
    # Get version
    if [ -z "$VERSION" ]; then
        VERSION=$(get_latest_version)
        print_status "Latest version: $VERSION"
    else
        print_status "Installing version: $VERSION"
    fi
    
    # Remove 'v' prefix from version for filename
    local version_number="${VERSION#v}"
    
    # Construct download URL
    local filename="tfrun_${version_number}_${platform}.tar.gz"
    local download_url="https://github.com/${REPO}/releases/download/${VERSION}/${filename}"
    
    print_status "Downloading from: $download_url"
    
    # Create temporary directory
    local tmp_dir=$(mktemp -d)
    local archive_path="${tmp_dir}/${filename}"
    
    # Download
    if command -v curl > /dev/null 2>&1; then
        if ! curl -L -o "$archive_path" "$download_url"; then
            print_error "Failed to download $filename"
            exit 1
        fi
    elif command -v wget > /dev/null 2>&1; then
        if ! wget -O "$archive_path" "$download_url"; then
            print_error "Failed to download $filename"
            exit 1
        fi
    else
        print_error "curl or wget is required"
        exit 1
    fi
    
    # Extract
    print_status "Extracting archive..."
    tar -xzf "$archive_path" -C "$tmp_dir"
    
    # Create install directory if it doesn't exist
    if [ ! -d "$INSTALL_DIR" ]; then
        print_status "Creating install directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR" || {
            print_error "Failed to create directory $INSTALL_DIR. Try running with sudo or choose a different directory."
            exit 1
        }
    fi
    
    # Install binary
    local binary_path="${tmp_dir}/tfrun"
    local install_path="${INSTALL_DIR}/${BINARY_NAME}"
    
    print_status "Installing to: $install_path"
    
    if ! cp "$binary_path" "$install_path"; then
        print_error "Failed to install binary. Try running with sudo or choose a different directory."
        exit 1
    fi
    
    # Make executable
    chmod +x "$install_path"
    
    # Cleanup
    rm -rf "$tmp_dir"
    
    print_success "tfrun $VERSION installed successfully!"
    
    # Verify installation
    if command -v "$BINARY_NAME" > /dev/null 2>&1; then
        print_success "tfrun is now available in your PATH"
        print_status "Version: $($BINARY_NAME --version)"
    else
        print_warning "tfrun installed to $install_path but not found in PATH"
        print_warning "You may need to add $INSTALL_DIR to your PATH"
        echo ""
        echo "Add this to your shell profile (.bashrc, .zshrc, etc.):"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\""
    fi
    
    echo ""
    print_status "Usage: tfrun --help"
}

# Main execution
main() {
    echo "🚀 tfrun installer"
    echo ""
    
    # Check if running as root and warn
    if [ "$EUID" -eq 0 ] && [ "$INSTALL_DIR" = "/usr/local/bin" ]; then
        print_warning "Running as root. Installing to system directory."
    fi
    
    install_tfrun
    
    echo ""
    print_success "Installation complete! 🎉"
}

# Run main function
main "$@"
