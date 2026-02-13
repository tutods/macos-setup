#!/usr/bin/env bash

# Nix Darwin Configuration Manager
# Usage: ./nix.sh <configuration> [options]
# Example: ./nix.sh macbook
# Example: ./nix.sh macbook --build-only
# Example: ./nix.sh macbook --force

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
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

# Show usage
show_usage() {
    echo "Usage: $0 <configuration> [options]"
    echo ""
    echo "Configurations:"
    echo "  macbook    - Personal MacBook configuration"
    echo "  work       - Work laptop configuration"
    echo ""
    echo "Options:"
    echo "  --build-only    Build configuration without applying"
    echo "  --force         Force rebuild even if no changes detected"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 macbook"
    echo "  $0 macbook --build-only"
    echo "  $0 work --force"
    exit 0
}

# Check if running from correct directory
check_directory() {
    if [[ ! -f "flake.nix" ]]; then
        print_error "Must be run from the .dotfiles directory (flake.nix not found)"
        exit 1
    fi
}

# Validate configuration exists
validate_config() {
    local config="$1"
    if [[ ! "$config" =~ ^(macbook|work)$ ]]; then
        print_error "Invalid configuration: $config"
        echo "Available configurations: macbook, work"
        exit 1
    fi
}

# Build configuration
build_config() {
    local config="$1"
    local force="$2"

    print_info "Building configuration: $config"

    local build_cmd="nix --extra-experimental-features 'nix-command flakes' build \".#darwinConfigurations.$config.system\""

    if [[ "$force" == "true" ]]; then
        build_cmd="$build_cmd --rebuild"
    fi

    if eval "$build_cmd"; then
        print_success "Configuration built successfully"
    else
        print_error "Failed to build configuration"
        exit 1
    fi
}

# Apply configuration
apply_config() {
    local config="$1"

    print_info "Applying configuration: $config"
    print_warning "This will require sudo privileges"

    # Check if darwin-rebuild is available locally (faster)
    if command -v darwin-rebuild &> /dev/null; then
        print_info "Using local darwin-rebuild"
        if sudo darwin-rebuild switch --flake ".#$config"; then
            print_success "Configuration applied successfully"
        else
            print_error "Failed to apply configuration"
            exit 1
        fi
    else
        print_info "Using remote darwin-rebuild"
        if sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/master#darwin-rebuild -- switch --flake ".#$config"; then
            print_success "Configuration applied successfully"
        else
            print_error "Failed to apply configuration"
            exit 1
        fi
    fi
}

# Main function
main() {
    # Check arguments
    if [[ $# -eq 0 ]]; then
        print_error "No configuration specified"
        show_usage
    fi

    local config="$1"
    local build_only=false
    local force=false

    # Parse arguments
    case "$config" in
        --help|-h)
            show_usage
            ;;
        *)
            # Parse additional options
            shift
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --build-only)
                        build_only=true
                        shift
                        ;;
                    --force)
                        force=true
                        shift
                        ;;
                    --help|-h)
                        show_usage
                        ;;
                    *)
                        print_error "Unknown option: $1"
                        show_usage
                        ;;
                esac
            done
            ;;
    esac

    # Validate environment
    check_directory
    validate_config "$config"

    print_info "Starting Nix Darwin configuration management"
    print_info "Configuration: $config"

    # Build configuration
    build_config "$config" "$force"

    # Apply configuration if not build-only
    if [[ "$build_only" == "false" ]]; then
        apply_config "$config"
        print_success "Nix Darwin configuration complete!"
        print_info "Run 'brew doctor' if you encounter any Homebrew issues"
    else
        print_success "Build complete! Use without --build-only to apply."
    fi
}

# Run main function with all arguments
main "$@"
