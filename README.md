# dir - Simple Enhanced Directory Listing

A Zsh script that enhances your terminal's directory listings with time-based badges, git integration, and clear formatting.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Shell](https://img.shields.io/badge/shell-zsh-green.svg)
![Dependencies](https://img.shields.io/badge/requires-eza-orange.svg)

## Why `dir`?

Traditional `ls` commands give you basic file information, but navigating modern codebases requires more context. **`dir`** bridges this gap by providing:

- **⏰ Time Intelligence**: Instantly see which files were just modified with color-coded badges
- **📊 Git Awareness**: Know how many files are untracked or staged without running `git status`
- **🎯 Smart Filtering**: Focus on what matters with glob patterns and depth control
- **⚡ Performance**: Optimized with caching and parallel operations for instant results
- **🎨 Beautiful Output**: Icons, colors, and tree views that make navigation a pleasure

## Features

### 🏷️ Time-Based Badges

See at a glance when files were last modified:

- 🔴 **JUST NOW** - Modified within the last minute
- 🟠 **X MINS AGO** - Modified within the last hour
- 🟡 **TODAY** - Modified today
- ⚪ **YESTERDAY** - Modified yesterday

### 📁 Intelligent Directory Display

- Tree view with configurable depth (0-4 levels)
- Smart handling of `node_modules` - shows module count without cluttering your view
- Automatic detection and special handling of empty directories
- File and folder counts with total size calculations

### 🔄 Git Integration

- Shows untracked and staged file counts in the summary
- Git status caching for performance (2-second cache)
- Seamless integration that doesn't slow down your listing

### ⚙️ Performance Optimizations

- Parallel execution of git commands
- Smart size calculation (skips for small directories)
- Combined find operations for efficiency
- Early exit strategies for edge cases

## Installation

### Prerequisites

Install `eza` (modern replacement for `ls`):

```bash
# macOS with Homebrew
brew install eza

# Linux/macOS with Cargo
cargo install eza
```

### Setup

1. Clone the repository:
```bash
git clone https://github.com/roelvangils/dir.git
cd dir
```

2. Make the script executable:
```bash
chmod +x dir.sh
```

3. Optional: Add to your PATH or create an alias:
```bash
# Add to ~/.zshrc
alias dir="/path/to/dir.sh"
```

## Usage

### Basic Commands

```bash
# List current directory (no tree)
./dir.sh

# Show with tree view (depth 1)
./dir.sh 1

# Show with tree view (depth 2)
./dir.sh 2

# Filter by pattern
./dir.sh "*.txt"

# Filter with specific depth
./dir.sh "*.txt" 2

# Show only hidden files
./dir.sh h

# Disable time badges
./dir.sh --no-badges
```

### Examples

#### Quick Status Check
```bash
$ ./dir.sh
```
Shows all files with time badges, perfect for seeing what you just modified.

#### Project Overview
```bash
$ ./dir.sh 2
```
Displays a 2-level tree view, ideal for understanding project structure.

#### Find Specific Files
```bash
$ ./dir.sh "*.json"
```
Lists only JSON files, great for finding configurations.

#### Check Hidden Files
```bash
$ ./dir.sh h
```
Shows hidden files and directories (dotfiles).

## Output Example

```
Size Date           Name
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
7.8k 2025-01-19 14:32 📄 README.md         JUST NOW
3.2k 2025-01-19 14:15 📄 package.json      17 MINS AGO
1.1k 2025-01-19 09:00 📄 .gitignore        TODAY
245B 2025-01-18 16:30 📁 src/              YESTERDAY

Found 3 files (±12.3k) and 1 folder. 2 files are untracked.
```

## Special Features

### Node.js Project Awareness

When in a Node.js project, `dir` intelligently handles `node_modules`:
- Excludes it from regular listings to reduce clutter
- Shows module count and total size in the summary
- When inside `node_modules`, automatically runs `npm ls --all`

### Git Repository Integration

In git repositories, the summary includes:
- Number of untracked files
- Number of staged files
- Efficient caching to avoid performance impact

### Smart Performance

The script includes several optimizations:
- Directories with ≤3 files skip size calculation for speed
- Git commands run in parallel using background jobs
- 2-second cache for git status to avoid repeated calls
- Combined find operations reduce filesystem traversal

## Configuration

While `dir` works great out of the box, you can customize its behavior:

- **Tree Depth**: Pass a number (0-4) to control tree view depth
- **Time Badges**: Use `--no-badges` to disable time badges
- **Filtering**: Use glob patterns to focus on specific files

## Requirements

- **Shell**: Zsh (uses Zsh-specific features)
- **Dependencies**: `eza` must be installed
- **Optional**: `npm` for enhanced Node.js project support
- **Optional**: `git` for repository status integration

## Why Not Just Use `eza` Directly?

While `eza` is excellent, `dir` adds:

1. **Time intelligence** - Color-coded badges for recent changes
2. **Smart summaries** - File counts, sizes, and git status
3. **Special handling** - Intelligent treatment of node_modules
4. **Performance** - Caching and optimizations for large directories
5. **Convenience** - Sensible defaults and shortcuts

## Contributing

Contributions are welcome! Feel free to:

- Report bugs or request features via [issues](https://github.com/roelvangils/dir/issues)
- Submit pull requests with improvements
- Share your usage experiences and suggestions

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

Created by Roel van Gils
