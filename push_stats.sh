#!/bin/bash
#
# Push time statistics
#
# Shows how long you've spent waiting for git push today, this week,
# and each of the previous weeks (up to 10 weeks back).
#
# Weeks run Sunday to Saturday.
#
# Usage:
#   ./push_stats.sh
#
# Reads from ~/.push_times.log
#

LOG_FILE="$HOME/.push_times.log"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "No log file found at $LOG_FILE"
  exit 1
fi

# Cross-platform: get today midnight and day-of-week (0=Sunday, 6=Saturday)
if date --version >/dev/null 2>&1; then
  today_start=$(date -d "today 00:00:00" +%s)
else
  today_start=$(date -v0H -v0M -v0S +%s)
fi
dow=$(date +%w)

# Start of current week (Sunday midnight)
week_start=$((today_start - dow * 86400))

# Build week boundary timestamps: index 0 = current week, 1 = last week, etc.
# We need 11 boundaries to define 10 previous weeks + current week
NUM_WEEKS=11
week_starts=()
for ((i = 0; i < NUM_WEEKS; i++)); do
  week_starts+=( $((week_start - i * 7 * 86400)) )
done

# Initialize accumulators
today_total=0
today_count=0
declare -a week_totals week_counts
for ((i = 0; i < NUM_WEEKS; i++)); do
  week_totals[$i]=0
  week_counts[$i]=0
done

# Oldest boundary we care about
oldest=${week_starts[$((NUM_WEEKS - 1))]}

while IFS='|' read -r timestamp _ duration _; do
  timestamp=$(echo "$timestamp" | tr -d ' ')
  seconds=$(echo "$duration" | tr -d ' s')

  # Skip entries older than our window
  if [[ "$timestamp" -lt "$oldest" ]]; then
    continue
  fi

  # Today
  if [[ "$timestamp" -ge "$today_start" ]]; then
    today_total=$(echo "$today_total + $seconds" | bc)
    ((today_count++))
  fi

  # Determine which week bucket
  for ((i = 0; i < NUM_WEEKS - 1; i++)); do
    if [[ "$timestamp" -ge "${week_starts[$i]}" ]]; then
      week_totals[$i]=$(echo "${week_totals[$i]} + $seconds" | bc)
      ((week_counts[$i]++))
      break
    fi
  done
done < "$LOG_FILE"

format_time() {
  local seconds=$1
  local mins=$(echo "$seconds / 60" | bc)
  local secs=$(printf "%.1f" "$(echo "$seconds - ($mins * 60)" | bc)")
  if [[ "$mins" -gt 0 ]]; then
    echo "${mins}m ${secs}s"
  else
    echo "${secs}s"
  fi
}

# Format a week range label (e.g. "Jan 26 - Feb 01")
format_week_label() {
  local start_ts=$1
  local end_ts=$(( start_ts + 6 * 86400 ))
  if date --version >/dev/null 2>&1; then
    local s=$(date -d "@$start_ts" "+%b %d")
    local e=$(date -d "@$end_ts" "+%b %d")
  else
    local s=$(date -r "$start_ts" "+%b %d")
    local e=$(date -r "$end_ts" "+%b %d")
  fi
  echo "$s - $e"
}

push_label() { if [[ "$1" -eq 1 ]]; then echo "push"; else echo "pushes"; fi; }

echo "Today:       $(format_time $today_total) ($today_count $(push_label $today_count))"
echo "This week:   $(format_time ${week_totals[0]}) (${week_counts[0]} $(push_label ${week_counts[0]}))"
echo ""

# Show previous weeks that have any pushes
has_history=false
for ((i = 1; i < NUM_WEEKS - 1; i++)); do
  if [[ "${week_counts[$i]}" -gt 0 ]]; then
    label=$(format_week_label "${week_starts[$i]}")
    printf "%-14s %s (%d %s)\n" "$label" "$(format_time ${week_totals[$i]})" "${week_counts[$i]}" "$(push_label ${week_counts[$i]})"
    has_history=true
  fi
done

if ! $has_history; then
  echo "No previous week data."
fi
