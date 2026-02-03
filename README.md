# Git Push Timer

Ever wondered how much of your life you've spent watching `git push` crawl across the network?

*Git Push Timer* tracks every `git push` you make and tells you exactly how long you've been waiting. Works with manual pushes, scripts, CI tools, and even AI coding assistants like Claude Code. Runs on Linux and macOS.

## Why?

- See if that "quick push" is actually eating 30 seconds of your day, every day
- Justify that faster internet connection to your boss
- Finally have data to back up "I spent all day waiting on git"
- Track push times across all your repos automatically

## Installation

```bash
# Install the git wrapper
sudo cp git.sh /usr/local/bin/git
sudo chmod +x /usr/local/bin/git

# That's it. Every git push is now tracked.
```

## Usage

Push times are automatically logged to `~/.push_times.log`.

Check your stats anytime:

```bash
./push_stats.sh
```

```
Today:     45.3s (4 pushes)
This week: 3m 22.1s (18 pushes)
```

## Log Format

Each push is logged as:

```
<timestamp> | git push | <duration> | <user> | <repo> | <branch>
```

Example:

```
1738250625 | git push | 8.2s | myuser | myrepo | main
1738251912 | git push | 3.9s | myuser | other-repo | feature-branch
```

## Uninstall

```bash
sudo rm /usr/local/bin/git
```

Your log file at `~/.push_times.log` is preserved.
