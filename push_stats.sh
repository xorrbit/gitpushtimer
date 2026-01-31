#!/bin/bash
#
# Push time statistics
#
# Shows how long you've spent waiting for git push today and this week.
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

today_start=$(date -d "today 00:00:00" +%s)
week_start=$(date -d "last monday 00:00:00" +%s)

# If today is Monday, "last monday" gives the previous week's Monday
if [[ $(date +%u) -eq 1 ]]; then
  week_start=$(date -d "today 00:00:00" +%s)
fi

today_total=0
week_total=0
today_count=0
week_count=0

while IFS='|' read -r timestamp _ duration _; do
  timestamp=$(echo "$timestamp" | tr -d ' ')
  seconds=$(echo "$duration" | tr -d ' s')

  if [[ "$timestamp" -ge "$week_start" ]]; then
    week_total=$(echo "$week_total + $seconds" | bc)
    ((week_count++))
  fi

  if [[ "$timestamp" -ge "$today_start" ]]; then
    today_total=$(echo "$today_total + $seconds" | bc)
    ((today_count++))
  fi
done < "$LOG_FILE"

format_time() {
  local seconds=$1
  local mins=$(echo "$seconds / 60" | bc)
  local secs=$(printf "%.1f" $(echo "$seconds - ($mins * 60)" | bc))
  if [[ "$mins" -gt 0 ]]; then
    echo "${mins}m ${secs}s"
  else
    echo "${secs}s"
  fi
}

echo "Today:     $(format_time $today_total) ($today_count pushes)"
echo "This week: $(format_time $week_total) ($week_count pushes)"
