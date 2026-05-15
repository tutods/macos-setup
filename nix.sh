#!/usr/bin/env bash
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; ITALIC='\033[3m'; NC='\033[0m'

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

_spinner_loop() {
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' msg="$1"
  printf '\033[?25l'
  while true; do
    for ((i=0; i<${#chars}; i++)); do
      printf "\r  ${CYAN}%s${NC}  %s" "${chars:$i:1}" "$msg"
      sleep 0.08
    done
  done
}

start_spinner() { _spinner_loop "$1" & SPINNER_PID=$!; }

stop_spinner() {
  [[ -z "$SPINNER_PID" ]] && return
  kill "$SPINNER_PID" 2>/dev/null || true
  wait "$SPINNER_PID" 2>/dev/null || true
  SPINNER_PID=""
  printf '\033[?25h'
  printf "\r%*s\r" 80 ""
}

# ── Cleanup on interrupt ──────────────────────────────────────────────────────
_BACKGROUND_PID=""

_cleanup() {
  stop_spinner
  [[ -n "$_BACKGROUND_PID" ]] && kill "$_BACKGROUND_PID" 2>/dev/null || true
  echo ""
  print_warning "Interrupted"
  exit 130
}
trap _cleanup INT TERM

# ── Elapsed time ──────────────────────────────────────────────────────────────
_fmt_elapsed() {
  local mins=$(( $1 / 60 )) secs=$(( $1 % 60 ))
  [[ $mins -gt 0 ]] && echo "${mins}m ${secs}s" || echo "${secs}s"
}

# ── Command runner ────────────────────────────────────────────────────────────
_CMD_LOG=""
LOG_FILE=""

run_cmd() {
  local title="$1"; shift
  _CMD_LOG=$(mktemp)
  local exit_code=0

  "$@" >"$_CMD_LOG" 2>&1 &
  _BACKGROUND_PID=$!
  local cmd_pid=$_BACKGROUND_PID
  start_spinner "$title"

  local shown=0
  while kill -0 "$cmd_pid" 2>/dev/null; do
    local total
    total=$(wc -l <"$_CMD_LOG" 2>/dev/null | awk '{print $1}')
    if (( total > shown )); then
      while IFS= read -r line; do
        if [[ "$line" =~ (building|copying|fetching|activating|error:|warning:) ]]; then
          stop_spinner
          printf "  ${DIM}%s${NC}\n" "$line"
          start_spinner "$title"
        fi
      done < <(sed -n "$((shown+1)),${total}p" "$_CMD_LOG" 2>/dev/null || true)
      shown=$total
    fi
    sleep 0.3
  done

  wait "$cmd_pid" || exit_code=$?
  stop_spinner
  _BACKGROUND_PID=""

  if [[ -n "$LOG_FILE" ]]; then
    { printf "\n=== %s | %s ===\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$title"
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
      [[ "$line" =~ ^error: ]] && echo -e "  ${RED}$line${NC}" || echo -e "  ${DIM}$line${NC}"
    done <<< "$errors"
  else
    echo -e "  ${BOLD}Last output:${NC}"
    tail -20 "$logfile" | sed 's/^/    /'
  fi

  if [[ -n "$LOG_FILE" ]]; then
    echo ""
    echo -e "  ${DIM}Full output: ${BOLD}$LOG_FILE${NC}"
  fi
  echo ""
}

# ── Banner ────────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "  ${CYAN}╭────────────────────────────╮${NC}"
  echo -e "  ${CYAN}│${NC}  ${BOLD}${CYAN}❄${NC}  ${BOLD}nix · darwin · deploy${NC}  ${CYAN}│${NC}"
  echo -e "  ${CYAN}╰────────────────────────────╯${NC}"
  echo ""
}

# ── Available configs ─────────────────────────────────────────────────────────
AVAILABLE_CONFIGS="macbook work"

get_target_user() {
  case "$1" in
    macbook) echo "tutods" ;;
    work)    echo "daniel.a.sousa" ;;
    *)       echo "${USER:-$(id -un)}" ;;
  esac
}

validate_config() {
  for c in $AVAILABLE_CONFIGS; do
    [[ "$c" == "$1" ]] && return 0
  done
  return 1
}

# ── Pure-bash arrow-key menu ──────────────────────────────────────────────────
# _tui_draw / _tui_select use these globals so _tui_draw can be top-level.
_TUI_SELECTED=""
_TUI_ITEMS=()
_TUI_SEL=0

_tui_draw() {
  local i count=${#_TUI_ITEMS[@]}
  for ((i = 0; i < count; i++)); do
    if ((i == _TUI_SEL)); then
      printf "  \033[96m▸ %s\033[0m\n" "${_TUI_ITEMS[$i]}"
    else
      printf "    \033[2m%s\033[0m\n" "${_TUI_ITEMS[$i]}"
    fi
  done
}

# Returns 1 if user pressed q/ESC; result written to _TUI_SELECTED.
_tui_select() {
  _TUI_ITEMS=("$@")
  _TUI_SEL=0
  local count=$# k1 k2 k3 quit=0
  local stty_save
  stty_save=$(stty -g 2>/dev/null) || stty_save=""

  [[ -n "$stty_save" ]] && stty -echo 2>/dev/null || true
  printf '\033[?25l\033[?7l'
  _tui_draw

  while true; do
    IFS= read -rsn1 k1
    if [[ $k1 == $'\x1b' ]]; then
      IFS= read -rsn1 -t 0.1 k2 || true
      IFS= read -rsn1 -t 0.1 k3 || true
      if [[ $k2 == '[' ]]; then
        case $k3 in
          A) ((_TUI_SEL > 0))          && ((_TUI_SEL--)) ;;
          B) ((_TUI_SEL < count - 1))  && ((_TUI_SEL++)) ;;
        esac
      else
        quit=1; break
      fi
    elif [[ $k1 == '' ]]; then
      break
    elif [[ $k1 == q || $k1 == Q ]]; then
      quit=1; break
    fi
    printf "\033[%dA" "$count"
    _tui_draw
  done

  [[ -n "$stty_save" ]] && stty "$stty_save" 2>/dev/null || true
  printf '\033[?25h\033[?7h'
  printf "\033[%dA\033[J" "$count"
  ((quit)) && return 1
  _TUI_SELECTED="${_TUI_ITEMS[$_TUI_SEL]}"
}

# ── Interactive config picker ─────────────────────────────────────────────────
# Result written to SELECTED_CONFIG (not stdout) so terminal output stays intact.
SELECTED_CONFIG=""

select_config() {
  print_banner
  echo -e "  ${BOLD}Select a machine:${NC}"
  echo ""

  if command -v fzf &>/dev/null; then
    SELECTED_CONFIG=$(printf '%s\n' $AVAILABLE_CONFIGS | fzf \
      --height=~40% \
      --layout=reverse \
      --border=rounded \
      --prompt="  Machine > " \
      --color="border:cyan,pointer:cyan,header:cyan" \
      --header="↑/↓ navigate  ENTER select  ESC quit") || true
    [[ -z "$SELECTED_CONFIG" ]] && { echo ""; exit 0; }
  else
    echo -e "  ${DIM}${ITALIC}↑/↓ navigate  ENTER select  q quit${NC}"
    echo ""
    # shellcheck disable=SC2086
    _tui_select $AVAILABLE_CONFIGS || exit 0
    SELECTED_CONFIG="$_TUI_SELECTED"
  fi
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
  echo "    --log <file>      Save full command output to file"
  echo "    --help, -h        Show this help message"
  echo ""
  echo -e "  ${BOLD}Examples${NC}"
  echo "    $0                        Interactive machine picker"
  echo "    $0 macbook                Build and apply"
  echo "    $0 macbook --build-only   Build only"
  echo "    $0 macbook --dry-run      Preview changes"
  echo "    $0 macbook --log out.log  Save full log"
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
  [[ -d ".hooks" ]] && git config core.hooksPath .hooks 2>/dev/null || true
}

# ── AI provider key setup ────────────────────────────────────────────────────
check_ai_keys() {
  local secrets_file="$HOME/.config/fish/secrets.fish"
  local any_prompted=0

  _key_exists() {
    local var="$1"
    [ -n "${!var:-}" ] && return 0
    [ -f "$secrets_file" ] && grep -q "set -gx ${var} " "$secrets_file" && return 0
    return 1
  }

  _prompt_key() {
    local var="$1" label="$2"
    if _key_exists "$var"; then
      print_dim "$label configured ✓"
      return
    fi
    local value=""
    read -rp "  Enter $label API key (empty to skip): " value
    if [ -n "$value" ]; then
      mkdir -p "$(dirname "$secrets_file")"
      printf 'set -gx %s "%s"\n' "$var" "$value" >> "$secrets_file"
      print_success "$label → secrets.fish"
      any_prompted=1
    else
      print_dim "$label skipped"
    fi
  }

  echo ""
  print_step "AI Provider Keys"
  print_dim "Stored in ~/.config/fish/secrets.fish (never committed)"
  echo ""
  _prompt_key "Z_AI_API_KEY"         "z.AI (GLM coding plan)"
  _prompt_key "OLLAMA_API_KEY"       "Ollama Cloud"
  _prompt_key "OPENCODE_API_KEY"     "OpenCode Go"
  _prompt_key "NVIDIA_API_KEY"       "NVIDIA NIM"
  echo ""
}

# ── Git identity setup ────────────────────────────────────────────────────────
setup_private_git() {
  local config="$1"
  local target_user
  target_user=$(get_target_user "$config")

  local target_home="/Users/$target_user"
  [[ "$target_user" == "${USER:-}" ]] && target_home="$HOME"

  local private_file="$target_home/.config/git/private"

  [[ "$target_user" != "${USER:-}" ]] && print_info "Using git identity for ${target_user}"

  if [[ -f "$private_file" ]]; then
    print_dim "Private git config found ✓"
    return 0
  fi

  print_warning "Private git config not found at $private_file"
  echo -e "     ${YELLOW}Git user.name and user.email are required.${NC}"
  echo -e "     ${YELLOW}See docs/secrets.md for details.${NC}"
  echo ""

  local name email
  read -rp "  Enter your git user.name: " name
  read -rp "  Enter your git user.email: " email

  if [[ -z "$name" || -z "$email" ]]; then
    print_error "Both name and email are required. Skipping private git config."
    return 1
  fi

  if [[ "$target_user" == "${USER:-}" ]]; then
    mkdir -p "$(dirname "$private_file")"
    git config --file "$private_file" user.name "$name"
    git config --file "$private_file" user.email "$email"
  else
    sudo -u "$target_user" mkdir -p "$(dirname "$private_file")"
    sudo -u "$target_user" git config --file "$private_file" user.name "$name"
    sudo -u "$target_user" git config --file "$private_file" user.email "$email"
  fi

  print_success "Private git config created at $private_file"
}

# ── Build ─────────────────────────────────────────────────────────────────────
build_config() {
  local config="$1" force="$2" step="$3"

  print_step "$step Building"
  print_dim "Config: $config"

  local build_cmd=(nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.$config.system")
  [[ "$force" == "true" ]] && build_cmd+=(--rebuild)

  local t0=$SECONDS exit_code=0
  run_cmd "Building ${config}…" "${build_cmd[@]}" || exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    print_success "Built in $(_fmt_elapsed $(( SECONDS - t0 )))"
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
    print_success "Preview completed in $(_fmt_elapsed $(( SECONDS - t0 )))"
    echo ""

    local changes
    changes=$(grep -E "^(these [0-9]+ derivations?|these [0-9]+ paths?|  /nix/store)" "$_CMD_LOG" 2>/dev/null | head -30 || true)
    if [[ -n "$changes" ]]; then
      echo -e "  ${BOLD}Changes:${NC}"
      while IFS= read -r line; do
        [[ "$line" =~ ^these ]] && echo -e "  ${CYAN}$line${NC}" || echo -e "  ${DIM}$line${NC}"
      done <<< "$changes"
    else
      print_dim "Nothing to build — already up to date."
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
  print_dim "Config: $config"

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
  print_dim "Authentication required — enter sudo password if prompted"
  if ! sudo -v; then
    print_error "Sudo authentication failed"
    exit 1
  fi
  echo ""

  local t0=$SECONDS exit_code=0
  run_cmd "Applying ${config}…" "${rebuild_cmd[@]}" || exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    print_success "Applied in $(_fmt_elapsed $(( SECONDS - t0 )))"
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
  [[ -n "$LOG_FILE" ]] && printf "  ${DIM}%-9s${NC}  %s\n" "Log" "$LOG_FILE"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  local config=""
  local build_only=false dry_run=false force=false

  # No args — interactive picker
  if [[ $# -eq 0 ]]; then
    check_directory
    select_config
    config="$SELECTED_CONFIG"
  else
    case "$1" in
      --help|-h) show_usage ;;
    esac

    if validate_config "$1"; then
      config="$1"
      shift
    fi
  fi

  # Parse remaining flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build-only)  build_only=true ;;
      --dry-run)     dry_run=true ;;
      --force)       force=true ;;
      --log)
        shift
        if [[ $# -eq 0 || "$1" == --* ]]; then
          print_error "--log requires a file path"
          exit 1
        fi
        LOG_FILE="$1"
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
    select_config
    config="$SELECTED_CONFIG"
  fi

  if ! validate_config "$config"; then
    print_error "Unknown configuration: $config"
    echo ""
    echo -e "  Available: ${CYAN}$AVAILABLE_CONFIGS${NC}"
    exit 1
  fi

  check_directory

  print_banner
  printf "  ${BOLD}%-9s${NC}  ${CYAN}%s${NC}\n" "Config" "$config"
  [[ "$build_only" == "true" ]] && print_dim "Mode: build only"
  [[ "$dry_run" == "true" ]]    && print_dim "Mode: dry run (preview only)"
  [[ "$force" == "true" ]]      && print_dim "Mode: force rebuild"
  [[ -n "$LOG_FILE" ]]          && print_dim "Log:  $LOG_FILE"
  print_divider

  local total_start=$SECONDS

  if [[ "$dry_run" == "true" ]]; then
    dry_run_config "$config" "[1/1]"
    print_summary "$config" "dry run" $(( SECONDS - total_start ))

  elif [[ "$build_only" == "true" ]]; then
    build_config "$config" "$force" "[1/1]"
    print_summary "$config" "build only" $(( SECONDS - total_start ))
    print_dim "Run $0 $config to apply."
    echo ""

  else
    check_ai_keys
    setup_private_git "$config"
    build_config "$config" "$force" "[1/2]"
    apply_config "$config" "$force" "[2/2]"
    print_summary "$config" "build + apply" $(( SECONDS - total_start ))
    print_dim "Tip: run brew doctor if you encounter Homebrew issues."
    echo ""
  fi
}

main "$@"
