#!/usr/bin/env bash
# Claude Code statusline — 2 lines.
# Line 1: model · dir · git branch + dirty counts
# Line 2: context bar + % · cost · duration · lines · 5h% · 7d%
#
# JSON session data arrives on stdin:
# https://code.claude.com/docs/en/statusline
set -uo pipefail

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REM=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

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
DURATION_SEC=$((DURATION_MS / 1000))
if [ "$DURATION_SEC" -ge 3600 ]; then
  HOURS=$((DURATION_SEC / 3600))
  MINS=$(((DURATION_SEC % 3600) / 60))
  DURATION_FMT="${HOURS}h${MINS}m"
else
  MINS=$((DURATION_SEC / 60))
  SECS=$((DURATION_SEC % 60))
  DURATION_FMT="${MINS}m${SECS}s"
fi

rate_color() {
  if [ "$1" -ge 90 ]; then printf '%b' "$RED"
  elif [ "$1" -ge 70 ]; then printf '%b' "$YELLOW"
  else printf '%b' "$GREEN"; fi
}

RATE=""
if [ -n "$FIVE_H" ]; then
  FIVE_H_INT=$(printf '%.0f' "$FIVE_H")
  RATE="$(rate_color "$FIVE_H_INT")5h ${FIVE_H_INT}%${RESET}"
fi
if [ -n "$WEEK" ]; then
  WEEK_INT=$(printf '%.0f' "$WEEK")
  if [ -n "$RATE" ]; then
    RATE="${RATE} ${DIM}·${RESET} $(rate_color "$WEEK_INT")7d ${WEEK_INT}%${RESET}"
  else
    RATE="$(rate_color "$WEEK_INT")7d ${WEEK_INT}%${RESET}"
  fi
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
LINE2="${LINE2} ${SEP} ⏱ ${DURATION_FMT}"
LINE2="${LINE2} ${SEP} ${GREEN}+${LINES_ADD}${RESET} ${RED}-${LINES_REM}${RESET}"
[ -n "$RATE" ] && LINE2="${LINE2} ${SEP} ${RATE}"
printf '%b\n' "$LINE2"
