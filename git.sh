#!/bin/bash
#
# Git push timing wrapper
#
# This script wraps the git command to log timing information for push operations.
# It logs: timestamp, command, duration, user, repository, and branch.
#
# Installation:
#   1. Copy this script to /usr/local/bin/git
#        sudo cp git.sh /usr/local/bin/git
#
#   2. Make it executable
#        sudo chmod +x /usr/local/bin/git
#
#   3. Ensure /usr/local/bin is in your PATH before /usr/bin
#        (it usually is by default)
#
# Log location:
#   ~/.push_times.log
#
# Log output format:
#   <unixtime> | git push | <duration>s | <user> | <repo> | <branch>
#
# Example log entry:
#   1738250625 | git push | 8.2s | myuser | myrepo | main
#
# To uninstall:
#   sudo rm /usr/local/bin/git
#

start=$(date +%s.%1N)
/usr/bin/git "$@"
rc=$?
end=$(date +%s.%1N)

if [[ "$1" == "push" ]]; then
  duration=$(printf "%.1f" $(echo "$end - $start" | bc))
  branch=$(/usr/bin/git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  remote_url=$(/usr/bin/git remote get-url origin 2>/dev/null || echo "unknown/unknown")

  # Parse user/repo from SSH (git@github.com:user/repo.git) or HTTPS (https://github.com/user/repo.git)
  user=$(echo "$remote_url" | sed -E 's#(git@[^:]+:|https?://[^/]+/)([^/]+)/.*#\2#')
  repo=$(echo "$remote_url" | sed -E 's#.*/([^/]+)(\.git)?$#\1#' | sed 's/\.git$//')

  echo "$(date +%s) | git push | ${duration}s | ${user} | ${repo} | ${branch}" >> "$HOME/.push_times.log"
fi

exit $rc
