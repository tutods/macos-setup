#!/usr/bin/env bash

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Print helpers ─────────────────────────────────────────────────────────────
print_info()    { echo -e "  ${BLUE}➜${NC}  $1"; }
print_success() { echo -e "  ${GREEN}✔${NC}  $1"; }
print_warning() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
print_error()   { echo -e "  ${RED}✖${NC}  $1"; }
print_step()    { echo -e "\n${BOLD}${CYAN}▸${NC} ${BOLD}$1${NC}"; }
print_dim()     { echo -e "  ${DIM}$1${NC}"; }
print_divider() { echo -e "  ${DIM}────────────────────────────────────────────${NC}"; }

# ── Spinner ───────────────────────────────────────────────────────────────────
SPINNER_PID=""
SPINNER_MSG=""
SPINNER_LAST_LINE=""

_spinner() {
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  tput civis  # hide cursor
  while true; do
    for ((i=0; i<${#chars}; i++)); do
      printf "\r  ${CYAN}%s${NC} %s" "${chars:$i:1}" "$SPINNER_MSG"
      sleep 0.08
    done
  done
}

start_spinner() {
  SPINNER_MSG="$1"
  _spinner &
  SPINNER_PID=$!
}

stop_spinner() {
  if [[ -n "$SPINNER_PID" ]]; then
    kill "$SPINNER_PID" 2>/dev/null || true
    wait "$SPINNER_PID" 2>/dev/null || true
    SPINNER_PID=""
    tput cnorm  # show cursor
    printf "\r%*s\r" 80 ""
  fi
}

# ── Timer ─────────────────────────────────────────────────────────────────────
TIMER_START=""

timer_start() {
  TIMER_START=$(date +%s)
}

timer_elapsed() {
  if [[ -z "$TIMER_START" ]]; then
    echo "0s"
    return
  fi
  local now=$(date +%s)
  local diff=$((now - TIMER_START))
  local mins=$((diff / 60))
  local secs=$((diff % 60))
  if [[ $mins -gt 0 ]]; then
    echo "${mins}m ${secs}s"
  else
    echo "${secs}s"
  fi
}

# ── Banner ────────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "  ${BOLD}${CYAN}❄${NC}  ${BOLD}nix · darwin · deploy${NC}"
  print_divider
}

# ── Available configs ─────────────────────────────────────────────────────────
AVAILABLE_CONFIGS="macbook work"

validate_config() {
  local config="$1"
  for c in $AVAILABLE_CONFIGS; do
    if [[ "$c" == "$config" ]]; then
      return 0
    fi
  done
  return 1
}

# ── Usage ─────────────────────────────────────────────────────────────────────
show_usage() {
  print_banner
  echo -e "  ${BOLD}Usage:${NC} $0 <configuration> [options]"
  echo ""
  echo -e "  ${BOLD}Configurations${NC} ${DIM}(defined in flake.nix)${NC}"
  echo "    macbook      Personal MacBook"
  echo "    work         Work laptop"
  echo ""
  echo -e "  ${BOLD}Options${NC}"
  echo "    --build-only    Build without applying"
  echo "    --force         Force rebuild even if no changes"
  echo "    --help, -h      Show this help message"
  echo ""
  echo -e "  ${BOLD}Examples${NC}"
  echo "    $0 macbook              Build and apply"
  echo "    $0 macbook --build-only  Build only"
  echo "    $0 work --force         Force rebuild"
  print_divider
  exit 0
}

# ── Checks ────────────────────────────────────────────────────────────────────
check_directory() {
  if [[ ! -f "flake.nix" ]]; then
    print_error "Must be run from the .dotfiles directory (flake.nix not found)"
    exit 1
  fi
}

setup_private_git() {
  local private_file="$HOME/.config/git/private"

  if [[ -f "$private_file" ]]; then
    print_dim "Private git config found ✓"
    return 0
  fi

  print_warning "Private git config not found at $private_file"
  echo -e "     ${YELLOW}Git user.name and user.email are required.${NC}"
  echo -e "     ${YELLOW}See docs/private-git-config.md for details.${NC}"
  echo ""

  local name email
  read -rp "  Enter your git user.name: " name
  read -rp "  Enter your git user.email: " email

  if [[ -z "$name" || -z "$email" ]]; then
    print_error "Both name and email are required. Skipping private git config."
    return 1
  fi

  mkdir -p "$(dirname "$private_file")"
  git config --file "$private_file" user.name "$name"
  git config --file "$private_file" user.email "$email"

  print_success "Private git config created at $private_file"
}

# ── Build ─────────────────────────────────────────────────────────────────────
build_config() {
  local config="$1"
  local force="$2"

  print_step "Building configuration"
  print_info "Config: ${BOLD}$config${NC}"

  local build_cmd=(nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.$config.system")
  [[ "$force" == "true" ]] && build_cmd+=(--rebuild)

  print_dim "Running: ${build_cmd[*]}"

  timer_start
  start_spinner "Building $config..."

  if "${build_cmd[@]}" 2>&1 | while IFS= read -r line; do
    if [[ "$line" =~ (building|copying|error) ]]; then
      stop_spinner
      echo -e "  ${DIM}$line${NC}"
      start_spinner "Building $config..."
    fi
  done; then
    stop_spinner
    local elapsed=$(timer_elapsed)
    print_success "Build completed in ${BOLD}$elapsed${NC}"
  else
    stop_spinner
    local elapsed=$(timer_elapsed)
    print_error "Build failed after $elapsed"
    exit 1
  fi
}

# ── Apply ─────────────────────────────────────────────────────────────────────
apply_config() {
  local config="$1"
  local force="$2"

  print_step "Applying configuration"
  print_info "Config: ${BOLD}$config${NC}"

  local switch_cmd=(switch --flake ".#$config")
  [[ "$force" == "true" ]] && switch_cmd+=(--rebuild)

  local rebuild_cmd
  if command -v darwin-rebuild &>/dev/null; then
    print_dim "Using local darwin-rebuild"
    rebuild_cmd=(sudo darwin-rebuild "${switch_cmd[@]}")
  else
    print_dim "Using remote darwin-rebuild"
    rebuild_cmd=(sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/nix-darwin-25.11#darwin-rebuild -- "${switch_cmd[@]}")
  fi

  print_dim "Running: darwin-rebuild ${switch_cmd[*]}"

  # Pre-authenticate with sudo so the password prompt is separate from
  # darwin-rebuild output. Once authenticated, sudo credentials are cached
  # for ~5 minutes and the spinner can run uninterrupted.
  echo ""
  echo -e "  ${DIM}Authentication required — enter sudo password if prompted${NC}"
  if ! sudo -v; then
    print_error "Sudo authentication failed"
    exit 1
  fi
  echo ""

  timer_start
  start_spinner "Applying $config..."

  # Redirect output to a temp file while spinner runs
  local tmpfile
  tmpfile=$(mktemp)
  local exit_code=0

  "${rebuild_cmd[@]}" > "$tmpfile" 2>&1 || exit_code=$?

  stop_spinner

  if [[ $exit_code -eq 0 ]]; then
    local elapsed=$(timer_elapsed)
    print_success "Configuration applied in ${BOLD}$elapsed${NC}"
  else
    local elapsed=$(timer_elapsed)
    print_error "Failed to apply configuration after $elapsed"
    echo ""
    echo -e "  ${DIM}Last output:${NC}"
    tail -50 "$tmpfile" | sed 's/^/    /'
    rm -f "$tmpfile"
    exit 1
  fi

  rm -f "$tmpfile"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  if [[ $# -eq 0 ]]; then
    print_error "No configuration specified"
    show_usage
  fi

  local config="$1"
  local build_only=false
  local force=false

  case "$config" in
    --help|-h) show_usage ;;
  esac

  if ! validate_config "$config"; then
    print_error "Unknown configuration: ${BOLD}$config${NC}"
    echo ""
    echo -e "  Available: ${CYAN}$AVAILABLE_CONFIGS${NC}"
    echo -e "  Run ${BOLD}$0 --help${NC} for more information"
    exit 1
  fi

  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build-only) build_only=true ;;
      --force)      force=true ;;
      --help|-h)    show_usage ;;
      *) print_error "Unknown option: $1"; show_usage ;;
    esac
    shift
  done

  check_directory

  print_banner
  print_info "Configuration: ${BOLD}$config${NC}"
  if [[ "$build_only" == "true" ]]; then
    print_dim "Mode: build only (no apply)"
  elif [[ "$force" == "true" ]]; then
    print_dim "Mode: force rebuild"
  fi
  print_divider

  if [[ "$build_only" == "false" ]]; then
    setup_private_git
  fi

  if [[ "$build_only" == "true" ]]; then
    build_config "$config" "$force"
    echo ""
    print_success "Build complete! Run ${BOLD}$0 $config${NC} to apply."
  else
    build_config "$config" "$force"
    apply_config "$config" "$force"
    echo ""
    print_divider
    print_success "Done! Run ${BOLD}brew doctor${NC} if you encounter Homebrew issues."
  fi

  echo ""
}

main "$@"