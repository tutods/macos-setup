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

_spinner() {
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  tput civis 2>/dev/null || true
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
    tput cnorm 2>/dev/null || true
    printf "\r%*s\r" 80 ""
  fi
}

_cleanup() {
  stop_spinner
  echo ""
  print_warning "Interrupted"
  exit 130
}
trap _cleanup INT TERM

# ── Elapsed time ──────────────────────────────────────────────────────────────
_fmt_elapsed() {
  local secs="$1"
  local mins=$(( secs / 60 ))
  secs=$(( secs % 60 ))
  [[ $mins -gt 0 ]] && echo "${mins}m ${secs}s" || echo "${secs}s"
}

# ── Command runner ────────────────────────────────────────────────────────────
_CMD_LOG=""
LOG_FILE=""   # set via --log <file> to persist full output for debugging

run_cmd() {
  local spinner_msg="$1"
  shift

  _CMD_LOG=$(mktemp)
  local cmd_pid exit_code=0

  "$@" >"$_CMD_LOG" 2>&1 &
  cmd_pid=$!
  start_spinner "$spinner_msg"

  local shown=0
  while kill -0 "$cmd_pid" 2>/dev/null; do
    local total
    total=$(wc -l <"$_CMD_LOG" 2>/dev/null | awk '{print $1}')
    if (( total > shown )); then
      while IFS= read -r line; do
        if [[ "$line" =~ (building|copying|fetching|activating|error:|warning:) ]]; then
          stop_spinner
          printf "  ${DIM}%s${NC}\n" "$line"
          start_spinner "$spinner_msg"
        fi
      done < <(sed -n "$((shown+1)),${total}p" "$_CMD_LOG" 2>/dev/null || true)
      shown=$total
    fi
    sleep 0.3
  done

  wait "$cmd_pid" || exit_code=$?
  stop_spinner

  # Append to debug log file if requested
  if [[ -n "$LOG_FILE" ]]; then
    {
      printf "\n=== %s | %s ===\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$spinner_msg"
      cat "$_CMD_LOG"
    } >> "$LOG_FILE"
  fi

  return "$exit_code"
}

# ── Error display ─────────────────────────────────────────────────────────────
show_errors() {
  local logfile="$1" label="$2"
  echo ""
  echo -e "  ${RED}${BOLD}✖ $label failed${NC}"
  echo ""

  local errors
  errors=$(grep -E "^(error:|       …|       at )" "$logfile" 2>/dev/null | head -25 || true)

  if [[ -n "$errors" ]]; then
    echo -e "  ${BOLD}Error details:${NC}"
    while IFS= read -r line; do
      if [[ "$line" =~ ^error: ]]; then
        echo -e "  ${RED}$line${NC}"
      else
        echo -e "  ${DIM}$line${NC}"
      fi
    done <<< "$errors"
  else
    echo -e "  ${BOLD}Last output:${NC}"
    tail -20 "$logfile" | sed 's/^/    /'
  fi

  if [[ -n "$LOG_FILE" ]]; then
    echo ""
    echo -e "  ${DIM}Full output saved to: ${BOLD}$LOG_FILE${NC}"
  fi
  echo ""
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
  for c in $AVAILABLE_CONFIGS; do
    [[ "$c" == "$1" ]] && return 0
  done
  return 1
}

# ── Interactive config picker ─────────────────────────────────────────────────
select_config() {
  local configs=($AVAILABLE_CONFIGS)
  local n=${#configs[@]}
  local selected=0

  print_banner
  echo -e "  ${BOLD}Select a machine:${NC}"
  echo ""

  # Draw initial list
  for i in "${!configs[@]}"; do
    if [[ $i -eq $selected ]]; then
      echo -e "  ${CYAN}▶  ${BOLD}${configs[$i]}${NC}"
    else
      echo -e "     ${DIM}${configs[$i]}${NC}"
    fi
  done

  tput civis 2>/dev/null || true

  while true; do
    local key seq
    IFS= read -rsn1 key

    case "$key" in
      $'\x1b')
        IFS= read -rsn2 -t 0.1 seq 2>/dev/null || seq=""
        case "$seq" in
          '[A') (( selected > 0 )) && (( selected-- )) ;;       # up
          '[B') (( selected < n - 1 )) && (( selected++ )) ;;   # down
        esac
        ;;
      '') break ;;                                               # enter
      q|Q) tput cnorm 2>/dev/null || true; echo ""; exit 0 ;;
    esac

    # Redraw: move cursor up n lines, reprint
    printf "\033[%dA" "$n"
    for i in "${!configs[@]}"; do
      printf "\033[2K"  # clear line
      if [[ $i -eq $selected ]]; then
        echo -e "  ${CYAN}▶  ${BOLD}${configs[$i]}${NC}"
      else
        echo -e "     ${DIM}${configs[$i]}${NC}"
      fi
    done
  done

  tput cnorm 2>/dev/null || true
  echo ""
  echo "${configs[$selected]}"
}

# ── Usage ─────────────────────────────────────────────────────────────────────
show_usage() {
  print_banner
  echo -e "  ${BOLD}Usage:${NC} $0 [configuration] [options]"
  echo ""
  echo -e "  ${BOLD}Configurations${NC} ${DIM}(defined in flake.nix)${NC}"
  echo "    macbook      Personal MacBook"
  echo "    work         Work laptop"
  echo -e "  ${DIM}  Omit to get an interactive picker.${NC}"
  echo ""
  echo -e "  ${BOLD}Options${NC}"
  echo "    --build-only      Build without applying"
  echo "    --dry-run         Preview what would change (no apply)"
  echo "    --force           Force rebuild even if no changes"
  echo "    --log <file>      Save full command output to file for debugging"
  echo "    --help, -h        Show this help message"
  echo ""
  echo -e "  ${BOLD}Examples${NC}"
  echo "    $0                        Interactive machine picker"
  echo "    $0 macbook                Build and apply"
  echo "    $0 macbook --build-only   Build only"
  echo "    $0 macbook --dry-run      Preview changes"
  echo "    $0 macbook --log out.log  Build, apply, save full log"
  echo "    $0 work --force           Force rebuild"
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
  local config="$1" force="$2" step="$3"

  print_step "$step Building"
  print_dim "Config: ${BOLD}$config${NC}"

  local build_cmd=(nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.$config.system")
  [[ "$force" == "true" ]] && build_cmd+=(--rebuild)

  local t0=$SECONDS exit_code=0
  run_cmd "Building ${config}…" "${build_cmd[@]}" || exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    print_success "Built in ${BOLD}$(_fmt_elapsed $(( SECONDS - t0 )))${NC}"
    rm -f "$_CMD_LOG"
  else
    show_errors "$_CMD_LOG" "Build"
    rm -f "$_CMD_LOG"
    exit 1
  fi
}

# ── Dry run ───────────────────────────────────────────────────────────────────
dry_run_config() {
  local config="$1" step="$2"

  print_step "$step Previewing changes"
  print_dim "Showing what would be built or fetched (no changes applied)"

  local dry_cmd=(nix --extra-experimental-features 'nix-command flakes' build --dry-run ".#darwinConfigurations.$config.system")

  local t0=$SECONDS exit_code=0
  run_cmd "Previewing ${config}…" "${dry_cmd[@]}" || exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    print_success "Preview completed in ${BOLD}$(_fmt_elapsed $(( SECONDS - t0 )))${NC}"
    echo ""

    local changes
    changes=$(grep -E "^(these [0-9]+ derivations?|these [0-9]+ paths?|  /nix/store)" "$_CMD_LOG" 2>/dev/null | head -30 || true)
    if [[ -n "$changes" ]]; then
      echo -e "  ${BOLD}Changes:${NC}"
      while IFS= read -r line; do
        if [[ "$line" =~ ^these ]]; then
          echo -e "  ${CYAN}$line${NC}"
        else
          echo -e "  ${DIM}$line${NC}"
        fi
      done <<< "$changes"
    else
      echo -e "  ${DIM}Nothing to build — already up to date.${NC}"
    fi
    rm -f "$_CMD_LOG"
  else
    show_errors "$_CMD_LOG" "Preview"
    rm -f "$_CMD_LOG"
    exit 1
  fi
}

# ── Apply ─────────────────────────────────────────────────────────────────────
apply_config() {
  local config="$1" force="$2" step="$3"

  print_step "$step Applying"
  print_dim "Config: ${BOLD}$config${NC}"

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

  echo ""
  echo -e "  ${DIM}Authentication required — enter sudo password if prompted${NC}"
  if ! sudo -v; then
    print_error "Sudo authentication failed"
    exit 1
  fi
  echo ""

  local t0=$SECONDS exit_code=0
  run_cmd "Applying ${config}…" "${rebuild_cmd[@]}" || exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    print_success "Applied in ${BOLD}$(_fmt_elapsed $(( SECONDS - t0 )))${NC}"
    rm -f "$_CMD_LOG"
  else
    show_errors "$_CMD_LOG" "Apply"
    rm -f "$_CMD_LOG"
    exit 1
  fi
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
  local config="$1" mode="$2" total_secs="$3"
  echo ""
  print_divider
  echo ""
  echo -e "  ${GREEN}${BOLD}✔  All done${NC}"
  echo ""
  printf "  ${DIM}%-9s${NC}  ${BOLD}${CYAN}%s${NC}\n" "Config"  "$config"
  printf "  ${DIM}%-9s${NC}  %s\n"                    "Mode"    "$mode"
  printf "  ${DIM}%-9s${NC}  %s\n"                    "Time"    "$(_fmt_elapsed "$total_secs")"
  if [[ -n "$LOG_FILE" ]]; then
    printf "  ${DIM}%-9s${NC}  %s\n"                  "Log"     "$LOG_FILE"
  fi
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  local config=""
  local build_only=false dry_run=false force=false

  # No args — show interactive picker
  if [[ $# -eq 0 ]]; then
    check_directory
    config=$(select_config)
  else
    case "$1" in
      --help|-h) show_usage ;;
    esac

    # First arg is a config name or a flag
    if validate_config "$1"; then
      config="$1"
      shift
    fi
  fi

  # Parse remaining flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build-only) build_only=true ;;
      --dry-run)    dry_run=true ;;
      --force)      force=true ;;
      --log)
        shift
        if [[ $# -eq 0 || "$1" == --* ]]; then
          print_error "--log requires a file path"
          exit 1
        fi
        LOG_FILE="$1"
        # Initialise / clear the log file
        printf "# nix.sh log — %s\n\n" "$(date '+%Y-%m-%d %H:%M:%S')" > "$LOG_FILE"
        ;;
      --help|-h) show_usage ;;
      *)
        if [[ -z "$config" ]] && validate_config "$1"; then
          config="$1"
        else
          print_error "Unknown option: $1"
          show_usage
        fi
        ;;
    esac
    shift
  done

  if [[ -z "$config" ]]; then
    check_directory
    config=$(select_config)
  fi

  if ! validate_config "$config"; then
    print_error "Unknown configuration: ${BOLD}$config${NC}"
    echo ""
    echo -e "  Available: ${CYAN}$AVAILABLE_CONFIGS${NC}"
    exit 1
  fi

  check_directory

  print_banner
  printf "  ${BOLD}%-9s${NC}  ${CYAN}%s${NC}\n" "Config" "$config"
  if [[ "$build_only" == "true" ]]; then
    print_dim "Mode: build only"
  elif [[ "$dry_run" == "true" ]]; then
    print_dim "Mode: dry run (preview only)"
  elif [[ "$force" == "true" ]]; then
    print_dim "Mode: force rebuild"
  fi
  [[ -n "$LOG_FILE" ]] && print_dim "Log:  $LOG_FILE"
  print_divider

  local total_start=$SECONDS

  if [[ "$dry_run" == "true" ]]; then
    dry_run_config "$config" "[1/1]"
    print_summary "$config" "dry run" $(( SECONDS - total_start ))

  elif [[ "$build_only" == "true" ]]; then
    build_config "$config" "$force" "[1/1]"
    print_summary "$config" "build only" $(( SECONDS - total_start ))
    echo -e "  ${DIM}Run ${BOLD}$0 $config${NC}${DIM} to apply.${NC}"
    echo ""

  else
    setup_private_git
    build_config  "$config" "$force" "[1/2]"
    apply_config  "$config" "$force" "[2/2]"
    print_summary "$config" "build + apply" $(( SECONDS - total_start ))
    echo -e "  ${DIM}Tip: run ${BOLD}brew doctor${NC}${DIM} if you encounter Homebrew issues.${NC}"
    echo ""
  fi
}

main "$@"
