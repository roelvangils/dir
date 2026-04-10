# dir - Enhanced Directory Listing

A modern directory listing tool built on top of `eza` with Git integration, Node.js project awareness, and visual badges for recently modified files.

## Features

- 🌳 **Tree view with configurable depth** (1-3 levels)
- 🆕 **Recent file badges** - Visual indicators for new and recently updated files
- 🔄 **Git repository status** - Shows untracked and staged files
- 📦 **Node.js project information** - Smart handling of node_modules
- 📊 **Smart file counting** - Human-readable file and folder counts
- 🎨 **Beautiful output** - Icons, colors, and formatting via eza
- ⚡ **Performance optimized** - Parallel processing for faster results
- 🔧 **Highly configurable** - Environment variables for customization

## Installation

### Prerequisites

1. **eza** - Modern replacement for ls (required)
   ```bash
   # macOS with Homebrew
   brew install eza
   
   # Using cargo
   cargo install eza
   ```

2. **git** - For repository status (optional)
   ```bash
   # Usually pre-installed, but if needed:
   brew install git
   ```

### Install the script

```bash
# Clone or download the script
curl -o ~/bin/dir https://raw.githubusercontent.com/yourusername/dir/main/dir_refactored.sh
chmod +x ~/bin/dir

# Or add as an alias in your .zshrc
alias dir='/path/to/dir_refactored.sh'
```

## Usage

### Basic usage

```bash
# List current directory
dir

# List with specific depth (1-3 levels)
dir "" 2

# Search for files matching a pattern
dir "*.txt"

# Show only hidden files
dir h
```

### Output examples

```
 file.txt    [NEW]       2023-12-15 10:30  1.2K
 script.sh   [updated]   2023-12-15 10:25  3.4K
📁 src                    2023-12-14 15:00     -
└──  main.js             2023-12-14 15:00  5.6K

    Found three files (± 10K) and one folder
    The node_modules folder (127 modules, ±243M) is not listed.
    Two untracked files, one staged file
```

## Configuration

Configure behavior using environment variables:

### Display Options

```bash
# Set default directory depth (1-3)
export DIR_DEPTH=2

# Time window for "recent" files (in minutes)
export DIR_RECENT_MINUTES=5

# Enable/disable badges
export DIR_SHOW_BADGES=true

# Show/hide Git status
export DIR_SHOW_GIT=true

# Show/hide Node modules info
export DIR_SHOW_NODE=true
```

### Visual Customization

```bash
# Icon display mode
export DIR_ICON_MODE=unicode  # Options: unicode, nerd, ascii, none

# Color scheme
export DIR_COLOR_SCHEME=auto  # Options: auto, light, dark
```

### Usage Examples

```bash
# Show 3 levels deep without Git status
DIR_DEPTH=3 DIR_SHOW_GIT=false dir

# Show files modified in last 10 minutes
DIR_RECENT_MINUTES=10 dir

# Disable all badges
DIR_SHOW_BADGES=false dir
```

## Badge System

The script displays visual badges for recently modified files:

- **[NEW]** - Black background with yellow text for files created within the time window
- **[updated]** - Yellow text for files modified within the time window

The default time window is 5 minutes but can be configured with `DIR_RECENT_MINUTES`.

## Performance Tips

1. **Large directories**: Use depth 1 for directories with many subdirectories
   ```bash
   dir "" 1
   ```

2. **Disable features**: Turn off unused features for faster performance
   ```bash
   DIR_SHOW_BADGES=false DIR_SHOW_GIT=false dir
   ```

3. **Use patterns**: Filter results to reduce processing
   ```bash
   dir "*.js"
   ```

## Customization

### Modifying Icons

Edit the `ICONS` array in the script:

```bash
declare -A ICONS=(
    ["node"]=""     # Node.js icon
    ["git"]=""      # Git icon
    ["new"]="NEW"       # New file badge
    ["updated"]="UPD"   # Updated file badge
)
```

### Changing Colors

Modify the `COLORS` array:

```bash
declare -A COLORS=(
    ["italic_gray"]="\033[3;90m"
    ["bold"]="\033[1m"
    ["yellow_bg_black"]="\033[43;30m"
    ["yellow"]="\033[33m"
)
```

### Time Windows

Adjust how "recent" is defined:

```bash
# Show files modified in last hour
export DIR_RECENT_MINUTES=60

# Show files modified today
export DIR_RECENT_MINUTES=$((24 * 60))
```

## Troubleshooting

### Common Issues

1. **"eza: command not found"**
   - Install eza: `brew install eza`

2. **No icons displayed**
   - Ensure your terminal supports Unicode
   - Try setting: `export DIR_ICON_MODE=ascii`

3. **Git status not showing**
   - Ensure you're in a Git repository
   - Check git is installed: `which git`

4. **Performance issues**
   - Reduce depth: `dir "" 1`
   - Disable badges: `export DIR_SHOW_BADGES=false`

### Debug Mode

Run with debug information:

```bash
# Enable shell debugging
set -x
dir
set +x
```

## Advanced Usage

### Integration with other tools

```bash
# Pipe to grep
dir | grep -E "\.js$"

# Save listing to file
dir > directory_contents.txt

# Use with watch for live updates
watch -n 2 'dir'
```

### Shell Functions

Add helpful functions to your `.zshrc`:

```bash
# Quick directory overview
dirsum() {
    DIR_DEPTH=1 DIR_SHOW_BADGES=false dir
}

# Show only recent changes
dirnew() {
    DIR_RECENT_MINUTES="${1:-5}" dir
}

# Deep directory exploration
dirdeep() {
    DIR_DEPTH=3 dir
}
```

## Contributing

Contributions are welcome! The script is designed to be self-contained in a single file for easy distribution.

### Development Guidelines

1. Maintain single-file structure
2. Ensure eza compatibility
3. Test with both zsh and bash (compatibility mode)
4. Document new environment variables
5. Keep performance in mind

## License

MIT License - feel free to use and modify as needed.

## Acknowledgments

- Built on top of [eza](https://github.com/eza-community/eza) - A modern replacement for ls
- Inspired by the need for better directory visualization
- Thanks to all contributors and users

## Version History

- **2.0.0** - Complete refactor with badges, performance improvements, and configuration options
- **1.0.0** - Initial version with basic eza integration