# Dir.sh Refactoring Plan

## Overview
This document outlines a comprehensive refactoring plan for the `dir.sh` script to modernize its structure, improve performance, and add new features while maintaining all existing functionality within a single file.

## Current State Analysis
The script currently:
- Uses `eza` for enhanced directory listing
- Provides file/folder counts with size information
- Shows node_modules information when present
- Displays Git status for repositories
- Supports glob patterns and hidden files mode

## Refactoring Goals

### 1. Improved Error Handling
- **Command availability checks**: Verify `eza`, `git`, and other commands exist
- **Directory access validation**: Handle permission errors gracefully
- **Fallback mechanisms**: Provide alternatives when primary commands fail
- **User-friendly error messages**: Clear, actionable error outputs

### 2. Function-Based Architecture
Break down the script into logical functions:

```bash
# Core display functions
display_directory_contents()
format_file_entry()
calculate_directory_stats()

# Status information functions
show_node_modules_info()
show_git_status()
show_recent_changes()

# Utility functions
check_dependencies()
parse_arguments()
get_config_value()
format_size()
pluralize_word()

# Badge generation functions
generate_new_badge()
generate_updated_badge()
check_file_age()
```

### 3. Icon Management System
```bash
# Icon variables at the top of the script
declare -A ICONS=(
    ["node"]=""
    ["git"]=""
    ["new"]="🆕"
    ["updated"]="🔄"
    ["folder"]="📁"
    ["file"]="📄"
)

# Configuration for icon display
ICON_MODE="${DIR_ICON_MODE:-unicode}"  # unicode, nerd, ascii, none
```

### 4. Performance Optimizations
- **Parallel processing**: Use background jobs for independent operations
- **Caching**: Store results of expensive operations (file counts, sizes)
- **Early exits**: Skip unnecessary operations based on conditions
- **Efficient commands**: Replace multiple `find` calls with single passes
- **Minimize subshells**: Use built-in string operations where possible

### 5. Configuration Options
```bash
# Environment variables for configuration
DIR_DEPTH="${DIR_DEPTH:-1}"                    # Default depth (1-3)
DIR_RECENT_MINUTES="${DIR_RECENT_MINUTES:-5}"  # Time for "recent" files
DIR_SHOW_BADGES="${DIR_SHOW_BADGES:-true}"     # Enable/disable badges
DIR_SHOW_GIT="${DIR_SHOW_GIT:-true}"          # Git status display
DIR_SHOW_NODE="${DIR_SHOW_NODE:-true}"        # Node modules info
DIR_COLOR_SCHEME="${DIR_COLOR_SCHEME:-auto}"   # Color preferences
```

### 6. New Features: Recent File Badges

#### Badge Implementation Strategy
1. **File timestamp checking**: Use `find -mmin` and `-cmin` for efficiency
2. **Badge formatting**: 
   - NEW: Black background, yellow text for files created < 5 min ago
   - Updated: Yellow background for files modified < 5 min ago
3. **Integration with eza**: Post-process eza output to add badges

#### Badge Display Format
```
file.txt    [NEW]      # Created within 5 minutes
script.sh   [updated]  # Modified within 5 minutes
```

### 7. Enhanced README Structure
```markdown
# dir - Enhanced Directory Listing

## Features
- Tree view with configurable depth (1-3 levels)
- Recent file badges (NEW/updated)
- Git repository status
- Node.js project information
- Smart file counting and size calculation

## Installation
[Installation instructions]

## Usage
[Usage examples with screenshots]

## Configuration
[All environment variables and their effects]

## Customization
[How to modify icons, colors, timeframes]

## Performance Tips
[Best practices for large directories]
```

## Implementation Timeline

### Phase 1: Core Refactoring (Priority: High)
1. Create function structure
2. Implement error handling
3. Add dependency checking

### Phase 2: Feature Enhancement (Priority: High)
1. Implement badge system for recent files
2. Add configurable depth levels (1-3)
3. Integrate badges with eza output

### Phase 3: Optimization (Priority: Medium)
1. Implement parallel processing
2. Add caching mechanisms
3. Optimize command usage

### Phase 4: Configuration (Priority: Medium)
1. Add environment variable support
2. Implement icon management
3. Create configuration validation

### Phase 5: Documentation (Priority: Low)
1. Write comprehensive README
2. Add inline documentation
3. Create usage examples

## Technical Considerations

### Badge Implementation Details
```bash
# Function to check file age and generate badge
get_file_badge() {
    local file="$1"
    local current_time=$(date +%s)
    local file_mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null)
    local file_ctime=$(stat -f %B "$file" 2>/dev/null || stat -c %W "$file" 2>/dev/null)
    
    local age_minutes=$(( (current_time - file_mtime) / 60 ))
    local create_minutes=$(( (current_time - file_ctime) / 60 ))
    
    if [[ $create_minutes -lt 5 ]]; then
        echo -e "\033[43;30m NEW \033[0m"  # Yellow bg, black text
    elif [[ $age_minutes -lt 5 ]]; then
        echo -e "\033[33m[updated]\033[0m"  # Yellow text
    fi
}
```

### Performance Optimization Example
```bash
# Parallel execution for independent operations
{
    get_git_status &
    get_node_modules_info &
    calculate_directory_stats &
    wait
} 2>/dev/null
```

## Success Criteria
- All existing functionality preserved
- Script remains in single file
- Measurable performance improvement (>20% faster for large directories)
- Clear error messages for all failure scenarios
- Badges correctly displayed for recent files
- Configuration options work as documented
- README provides comprehensive guidance

## Risk Mitigation
- Maintain backward compatibility
- Test on various shells (zsh, bash compatibility layer)
- Handle edge cases (empty directories, no permissions, missing commands)
- Provide fallbacks for all enhanced features