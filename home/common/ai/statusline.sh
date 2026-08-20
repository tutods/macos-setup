#!/usr/bin/env bash
# Claude Code statusline, 2 lines.
# Line 1: model · dir · git branch + dirty counts
# Line 2: context bar + % · cost · lines · 5h% + reset · 7d% + reset
#
# JSON session data arrives on stdin:
# https://code.claude.com/docs/en/statusline
set -uo pipefail

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REM=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

if [ "${PCT:-0}" -ge 90 ]; then
  BAR_COLOR="$RED"
elif [ "${PCT:-0}" -ge 70 ]; then
  BAR_COLOR="$YELLOW"
else
  BAR_COLOR="$GREEN"
fi

FILLED=$((PCT / 10))
[ "$FILLED" -lt 0 ] && FILLED=0
[ "$FILLED" -gt 10 ] && FILLED=10
EMPTY=$((10 - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v F "%${FILLED}s" && BAR="${F// /█}"
[ "$EMPTY" -gt 0 ] && printf -v E "%${EMPTY}s" && BAR="${BAR}${E// /░}"

GIT=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  if [ -z "$BRANCH" ]; then
    BRANCH=$(git rev-parse --short HEAD 2>/dev/null || echo "detached")
  fi
  STAGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  MODIFIED=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  GIT=" ${DIM}on${RESET} 🌿 ${BRANCH}"
  [ "${STAGED:-0}" -gt 0 ] && GIT="${GIT} ${GREEN}+${STAGED}${RESET}"
  [ "${MODIFIED:-0}" -gt 0 ] && GIT="${GIT} ${YELLOW}~${MODIFIED}${RESET}"
  [ "${UNTRACKED:-0}" -gt 0 ] && GIT="${GIT} ${DIM}?${UNTRACKED}${RESET}"
fi

COST_FMT=$(printf '$%.2f' "$COST")

rate_color() {
  if [ "$1" -ge 90 ]; then printf '%b' "$RED"
  elif [ "$1" -ge 70 ]; then printf '%b' "$YELLOW"
  else printf '%b' "$GREEN"; fi
}

fmt_reset() {
  [ -z "${1:-}" ] && return 0
  local now diff days hours mins
  now=$(date +%s)
  diff=$(( $1 - now ))
  [ "$diff" -le 0 ] && { printf 'now'; return; }
  days=$(( diff / 86400 ))
  hours=$(( (diff % 86400) / 3600 ))
  mins=$(( (diff % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    printf '%dd%dh' "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then
    printf '%dh%dm' "$hours" "$mins"
  else
    printf '%dm' "$mins"
  fi
}

RATE=""
if [ -n "$FIVE_H" ]; then
  FIVE_H_INT=$(printf '%.0f' "$FIVE_H")
  FIVE_H_FMT=$(fmt_reset "$FIVE_H_RESET")
  RATE="$(rate_color "$FIVE_H_INT")5h ${FIVE_H_INT}%${RESET}"
  [ -n "$FIVE_H_FMT" ] && RATE="${RATE} ${DIM}in ${FIVE_H_FMT}${RESET}"
fi
if [ -n "$WEEK" ]; then
  WEEK_INT=$(printf '%.0f' "$WEEK")
  WEEK_FMT=$(fmt_reset "$WEEK_RESET")
  if [ -n "$RATE" ]; then
    RATE="${RATE} ${DIM}·${RESET} $(rate_color "$WEEK_INT")7d ${WEEK_INT}%${RESET}"
  else
    RATE="$(rate_color "$WEEK_INT")7d ${WEEK_INT}%${RESET}"
  fi
  [ -n "$WEEK_FMT" ] && RATE="${RATE} ${DIM}in ${WEEK_FMT}${RESET}"
fi

DIR_NAME="${DIR##*/}"
[ -z "$DIR_NAME" ] && DIR_NAME="?"

PR_NUM=$(echo "$input" | jq -r '.pr.number // empty')
PR=""
if [ -n "$PR_NUM" ]; then
  REVIEW=$(echo "$input" | jq -r '.pr.review_state // empty')
  case "$REVIEW" in
    approved) REVIEW_FMT="${GREEN}approved${RESET}" ;;
    pending) REVIEW_FMT="${YELLOW}pending${RESET}" ;;
    changes_requested) REVIEW_FMT="${RED}changes requested${RESET}" ;;
    draft) REVIEW_FMT="${DIM}draft${RESET}" ;;
    *) REVIEW_FMT="" ;;
  esac
  if [ -n "$REVIEW_FMT" ]; then
    PR=" ${DIM}·${RESET} ${DIM}PR${RESET} ${CYAN}#${PR_NUM}${RESET} ${DIM}(${RESET}${REVIEW_FMT}${DIM})${RESET}"
  else
    PR=" ${DIM}·${RESET} ${DIM}PR${RESET} ${CYAN}#${PR_NUM}${RESET}"
  fi
fi

SEP="${DIM}·${RESET}"
printf '%b\n' "${CYAN}${MODEL}${RESET} ${DIM}in${RESET} 📁 ${DIR_NAME}${GIT}${PR}"

LINE2="${BAR_COLOR}${BAR}${RESET} ${PCT}%"
LINE2="${LINE2} ${SEP} ${YELLOW}${COST_FMT}${RESET}"
LINE2="${LINE2} ${SEP} ${GREEN}+${LINES_ADD}${RESET} ${RED}-${LINES_REM}${RESET}"
[ -n "$RATE" ] && LINE2="${LINE2} ${SEP} ${RATE}"
printf '%b\n' "$LINE2"
