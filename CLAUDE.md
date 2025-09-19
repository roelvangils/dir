# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a single-file shell utility written in Zsh that provides an enhanced directory listing experience using `eza` (a modern replacement for `ls`).

## Key Commands

### Running the Script
```bash
# List current directory contents (no tree)
./dir.sh

# Show with tree depth 1
./dir.sh 1

# Show with tree depth 2
./dir.sh 2

# Filter listing by glob pattern
./dir.sh "*.txt"

# Filter with specific depth
./dir.sh "*.txt" 2

# Show only hidden files
./dir.sh h

# Disable time badges
./dir.sh --no-badges
```

### Dependencies
The script requires `eza` to be installed. Install it using:
```bash
# macOS with Homebrew
brew install eza

# or using cargo
cargo install eza
```

## Architecture

The `dir.sh` script is a performance-optimized Zsh utility with the following key features:

1. **Special Directory Handling**
   - Detects `node_modules` directories and runs `npm ls --all` instead
   - Early exit for empty directories
   - Git repository awareness with status caching

2. **Time Badge System**
   - Shows colored badges for recently modified files:
     - "JUST NOW" (red) - modified within the last minute
     - "X MINS AGO" (orange) - modified within the last hour
     - "TODAY" (yellow) - modified today
     - "YESTERDAY" (gray) - modified yesterday
   - Badges can be disabled with `--no-badges` flag

3. **Performance Optimizations**
   - Git status caching (2-second cache validity)
   - Parallel git command execution using background jobs
   - Combined find operations for file/folder counting
   - Skips size calculation for directories with ≤3 files

4. **Output Processing**
   - Integrates with `eza` for styled output with icons
   - Processes eza output line-by-line to inject time badges
   - Custom formatting functions for emphasis, numbers, and hyperlinks
   - Excludes `node_modules` and `.DS_Store` from listings

5. **Summary Statistics**
   - Shows file count and total size
   - Displays folder count (excluding node_modules)
   - Git status integration (untracked/staged files)
   - Special node_modules reporting with module count

## Important Notes

- The script assumes `eza` is installed and available in PATH
- It uses Zsh-specific syntax and won't work with other shells
- The script returns early if the directory is empty
- File counts exclude hidden files unless specifically requested with `h` flag
- Git status is cached for 2 seconds to improve performance
- Tree depth defaults to 0 (no tree) unless specified