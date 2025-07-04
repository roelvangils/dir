# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a single-file shell utility written in Zsh that provides an enhanced directory listing experience using `eza` (a modern replacement for `ls`).

## Key Commands

### Running the Script
```bash
# List current directory contents
./dir.sh

# Filter listing by glob pattern
./dir.sh "*.txt"

# Show only hidden files
./dir.sh h
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

This is a standalone shell script (`dir.sh`) with the following structure:

1. **Text Formatting Functions** (lines 8-47)
   - `_EM_()`: Italic gray text for emphasis
   - `_STRONG_()`: Bold text
   - `_A_()`: Clickable hyperlinks
   - `_HR_()`: Horizontal rule

2. **Main Listing Logic** (lines 49-82)
   - Two modes: regular listing or hidden files only (when passed "h")
   - Uses `eza` with custom flags for enhanced display
   - Excludes `node_modules` and `.DS_Store` files

3. **Summary Generation** (lines 84-134)
   - Counts files and folders matching the pattern
   - Displays human-readable summary with total size
   - Shows `node_modules` size if present (but doesn't list its contents)

## Important Notes

- The script assumes `eza` is installed and available in PATH
- It uses Zsh-specific syntax and won't work with other shells
- The script returns early if the directory is empty
- File counts exclude hidden files unless specifically requested