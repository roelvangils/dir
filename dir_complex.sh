#!/bin/zsh

# dir - Enhanced Directory Listing with eza
# A modern directory listing tool with Git integration, Node.js support, and recent file badges

# ==============================================================================
# CONFIGURATION AND CONSTANTS
# ==============================================================================

# Configuration via environment variables
readonly DIR_DEPTH="${DIR_DEPTH:-1}"                   # Default depth (1-3)
readonly DIR_RECENT_MINUTES="${DIR_RECENT_MINUTES:-5}" # Time for "recent" files
readonly DIR_SHOW_BADGES="${DIR_SHOW_BADGES:-true}"    # Enable/disable badges
readonly DIR_SHOW_GIT="${DIR_SHOW_GIT:-true}"          # Git status display
readonly DIR_SHOW_NODE="${DIR_SHOW_NODE:-true}"        # Node modules info
readonly DIR_COLOR_SCHEME="${DIR_COLOR_SCHEME:-auto}"  # Color preferences
readonly DIR_ICON_MODE="${DIR_ICON_MODE:-unicode}"     # Icon display mode

# Icon definitions
declare -A ICONS=(
    ["node"]=""
    ["git"]=""
    ["new"]="NEW"
    ["updated"]="UPDATED"
    ["folder"]="󰷏"
    ["file"]=""
)

# Color codes
declare -A COLORS=(
    ["italic_gray"]="\033[3;90m"
    ["bold"]="\033[1m"
    ["yellow_bg_black"]="\033[43;30m"
    ["yellow"]="\033[33m"
    ["dark_gray_bg_white"]="\033[48;5;236;97m"
    ["reset"]="\033[0m"
    ["dim_line"]="\033[38;5;232m"
)

# ==============================================================================
# ERROR HANDLING AND DEPENDENCIES
# ==============================================================================

# Set error handling
set -o pipefail

# Function to display errors
error() {
    echo "Error: $1" >&2
    return 1
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()

    # Check for eza
    if ! command -v eza &>/dev/null; then
        missing_deps+=("eza")
    fi

    # Check for git (optional)
    if [[ "$DIR_SHOW_GIT" == "true" ]] && ! command -v git &>/dev/null; then
        echo "Warning: git not found. Git status will be disabled." >&2
        DIR_SHOW_GIT="false"
    fi

    # If critical dependencies are missing, exit
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install missing dependencies:" >&2
        echo "  brew install ${missing_deps[*]}" >&2
        exit 1
    fi
}

# ==============================================================================
# TEXT FORMATTING FUNCTIONS
# ==============================================================================

# Print italic gray text
_EM_() {
    local text="$1"
    [[ -z "$text" ]] && return
    echo -ne "${COLORS[italic_gray]}${text}${COLORS[reset]}"
}

# Print bold text
_STRONG_() {
    local text="$1"
    [[ -z "$text" ]] && return
    echo -e "${COLORS[bold]}${text}${COLORS[reset]}"
}

# Print clickable link
_A_() {
    local url="$1"
    local text="${2:-$url}"
    echo -e "\033]8;;${url}\a${text}\033]8;;\a"
}

# Print horizontal rule
_HR_() {
    echo -e "${COLORS[dim_line]}$(printf "%$(tput cols)s" "" | tr ' ' '─')${COLORS[reset]}"
}

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

# Convert number to word (1-9)
num_to_word() {
    case $1 in
    1) echo "one" ;;
    2) echo "two" ;;
    3) echo "three" ;;
    4) echo "four" ;;
    5) echo "five" ;;
    6) echo "six" ;;
    7) echo "seven" ;;
    8) echo "eight" ;;
    9) echo "nine" ;;
    *) echo "$1" ;;
    esac
}

# Pluralize word based on count
pluralize() {
    local count=$1
    local singular=$2
    local plural=${3:-"${singular}s"}

    if [[ $count -eq 1 ]]; then
        echo "$singular"
    else
        echo "$plural"
    fi
}

# Format file size
format_size() {
    local size=$1
    echo "±$size"
}

# ==============================================================================
# BADGE FUNCTIONS (Removed - now integrated into process_eza_output_with_badges)
# ==============================================================================

# ==============================================================================
# CORE LISTING FUNCTIONS
# ==============================================================================

# Process eza output to add badges
process_eza_output_with_badges() {
    local line="$1"
    local show_badges="$2"

    # Skip if badges are disabled
    if [[ "$show_badges" != "true" ]]; then
        echo "$line"
        return
    fi

    # Skip header lines and empty lines
    if [[ "$line" =~ ^(Permissions|Size|Date|Name|$) ]] || [[ -z "$line" ]]; then
        echo "$line"
        return
    fi

    # Extract timestamp from eza output (format: 2025-07-04 19:13)
    # Remove ANSI codes and extract the timestamp
    local clean_line=$(echo "$line" | sed -E 's/\[[0-9;]+m//g')
    local timestamp=""
    
    # Match the date-time pattern (YYYY-MM-DD HH:MM)
    if [[ "$clean_line" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{2}:[0-9]{2}) ]]; then
        timestamp="${BASH_REMATCH[1]}"
    fi
    
    # If we found a timestamp, check if it's recent
    if [[ -n "$timestamp" ]]; then
        # Convert timestamp to seconds since epoch
        local file_time
        if [[ "$OSTYPE" == "darwin"* ]]; then
            file_time=$(date -j -f "%Y-%m-%d %H:%M" "$timestamp" "+%s" 2>/dev/null)
        else
            file_time=$(date -d "$timestamp" "+%s" 2>/dev/null)
        fi
        
        if [[ -n "$file_time" ]]; then
            local current_time=$(date +%s)
            local age_minutes=$(( (current_time - file_time) / 60 ))
            
            # Check if file is recent
            if [[ $age_minutes -lt ${DIR_RECENT_MINUTES:-5} ]]; then
                echo -e "${line} ${COLORS[dark_gray_bg_white]} ${ICONS[updated]} ${COLORS[reset]}"
            else
                echo "$line"
            fi
        else
            echo "$line"
        fi
    else
        echo "$line"
    fi
}

# Display directory contents with eza
display_directory_contents() {
    local glob="${1:-}"
    local depth="${2:-0}"
    local show_badges="${3:-$DIR_SHOW_BADGES}"

    local eza_args=(
        --group-directories-first
        --header
        --icons=always
        --long
        --no-user
        --sort modified
        --time-style long-iso
        --colour always
    )

    # Add tree arguments only if depth > 0
    if [[ "$glob" != "h" && "$depth" -gt 0 ]]; then
        eza_args+=(
            --tree
            --level "$depth"
            --no-permissions
        )
    elif [[ "$glob" != "h" ]]; then
        # No tree, but still no permissions
        eza_args+=(--no-permissions)
    fi

    # Set ignore patterns
    local ignore_patterns="node_modules|**/.DS_Store"
    if [[ "$glob" == "h" ]]; then
        ignore_patterns+="|.|.."
    fi

    eza_args+=(--ignore-glob="$ignore_patterns")

    # Execute eza command and process output for badges
    local eza_output
    local eza_cmd
    
    # Build the eza command
    if [[ "$glob" == "h" ]]; then
        # Show only hidden files - add --all flag for this mode
        eza_cmd=(eza "${eza_args[@]}" --all .*)
    else
        # Show files matching glob pattern
        if [[ -n "$glob" ]]; then
            eza_cmd=(eza "${eza_args[@]}" *"$glob"*)
        else
            eza_cmd=(eza "${eza_args[@]}")
        fi
    fi
    
    # Try to run eza with a timeout
    if command -v timeout &>/dev/null; then
        eza_output=$(timeout 2 "${eza_cmd[@]}" 2>/dev/null | sed 's/└/╰/g')
    else
        eza_output=$("${eza_cmd[@]}" 2>/dev/null | sed 's/└/╰/g')
    fi
    
    # If eza failed or timed out, fall back to ls
    if [[ -z "$eza_output" ]] && [[ "$glob" != "h" ]]; then
        if [[ -n "$glob" ]]; then
            eza_output=$(ls -la *"$glob"* 2>/dev/null)
        else
            eza_output=$(ls -la 2>/dev/null)
        fi
        # Add a note in the output that we're using ls
        if [[ -n "$eza_output" ]]; then
            eza_output="# Note: Using ls fallback (eza timed out)
$eza_output"
        fi
    fi
    
    # Process each line
    if [[ -n "$eza_output" ]]; then
        echo "$eza_output" | while IFS= read -r line; do
            process_eza_output_with_badges "$line" "$show_badges"
        done
    fi
}

# Calculate directory statistics
calculate_directory_stats() {
    local glob="${1:-}"
    local -A stats

    # Count files and folders
    if [[ -n "$glob" ]]; then
        stats[files]=$(find . -maxdepth 1 -type f -name "*$glob*" -not -name ".*" 2>/dev/null | wc -l | tr -d '[:space:]')
        stats[folders]=$(find . -maxdepth 1 -type d -name "*$glob*" -not -name ".*" 2>/dev/null | wc -l | tr -d '[:space:]')
    else
        stats[files]=$(find . -maxdepth 1 -type f -not -name ".*" 2>/dev/null | wc -l | tr -d '[:space:]')
        stats[folders]=$(find . -maxdepth 1 -type d -not -name ".*" 2>/dev/null | wc -l | tr -d '[:space:]')
    fi

    # Calculate total size
    if [[ -n "$(ls -A 2>/dev/null)" ]]; then
        stats[size]=$(du -sh . 2>/dev/null | awk '{print $1}')
    else
        stats[size]="0"
    fi

    echo "${stats[files]}|${stats[folders]}|${stats[size]}"
}

# Display summary information
display_summary() {
    local stats="$1"
    local files=$(echo "$stats" | cut -d'|' -f1)
    local folders=$(echo "$stats" | cut -d'|' -f2)
    local size=$(echo "$stats" | cut -d'|' -f3)

    # Build file count message
    local file_msg
    if [[ $files -eq 0 ]]; then
        file_msg="no files"
    elif [[ $files -eq 1 ]]; then
        file_msg="just one file"
    else
        file_msg="$(num_to_word $files) files"
    fi

    # Build folder count message
    local folder_msg=""
    if [[ $folders -gt 0 ]]; then
        if [[ $folders -eq 1 ]]; then
            folder_msg="and just one folder "
        else
            folder_msg="and $(num_to_word $folders) folders "
        fi
    fi

    echo -e "\n$(_EM_ "    Found $file_msg ($(format_size "$size")) $folder_msg")"
}

# ==============================================================================
# STATUS INFORMATION FUNCTIONS
# ==============================================================================

# Show node_modules information
show_node_modules_info() {
    [[ "$DIR_SHOW_NODE" != "true" ]] && return
    [[ ! -d "node_modules" ]] && return

    local node_size=$(du -sh node_modules 2>/dev/null | cut -f1)
    local module_count=$(find node_modules -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d '[:space:]')
    module_count=$((module_count - 1)) # Exclude node_modules itself

    echo -e "$(_EM_ "     The ")$(_A_ "file://$(pwd)/node_modules" "$(_EM_ "node_modules")")$(_EM_ " folder ($module_count modules, $(format_size "$node_size")) is not listed.")"
}

# Show git status
show_git_status() {
    [[ "$DIR_SHOW_GIT" != "true" ]] && return
    [[ ! -d ".git" ]] && return

    local untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d '[:space:]')
    local staged_count=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d '[:space:]')

    local messages=()

    # Add untracked files message if count > 0
    if [[ $untracked_count -gt 0 ]]; then
        messages+=("$(num_to_word $untracked_count) untracked $(pluralize $untracked_count "file")")
    fi

    # Add staged files message if count > 0
    if [[ $staged_count -gt 0 ]]; then
        messages+=("$(num_to_word $staged_count) staged $(pluralize $staged_count "file")")
    fi

    # Display if there's something to show
    if [[ ${#messages[@]} -gt 0 ]]; then
        local output=$(printf "%s, " "${messages[@]}")
        output=${output%, } # Remove trailing comma
        # Capitalize first letter
        output="$(echo ${output:0:1} | tr '[:lower:]' '[:upper:]')${output:1}"
        echo -e "$(_EM_ "     $output")"
    fi
}

# ==============================================================================
# MAIN FUNCTION
# ==============================================================================

main() {
    # Check if directory is empty
    if [[ -z "$(ls -A '.' 2>/dev/null)" ]]; then
        echo "This folder is empty."
        return 0
    fi

    # Check dependencies
    check_dependencies

    # Parse arguments
    local show_badges="$DIR_SHOW_BADGES"
    local args=()
    
    # Process all arguments
    for arg in "$@"; do
        if [[ "$arg" == "--no-badges" ]]; then
            show_badges="false"
        else
            args+=("$arg")
        fi
    done
    
    # Parse remaining arguments
    local first_arg="${args[0]:-}"
    local glob=""
    local depth="0" # Default to 0 (no tree)

    # Check if first argument is a number (depth)
    if [[ "$first_arg" =~ ^[0-9]+$ ]]; then
        depth="$first_arg"
    elif [[ "$first_arg" == "h" ]]; then
        glob="h"
    elif [[ -n "$first_arg" ]]; then
        # It's a glob pattern
        glob="$first_arg"
        # Check if second argument is depth
        if [[ -n "${args[1]}" && "${args[1]}" =~ ^[0-9]+$ ]]; then
            depth="${args[1]}"
        fi
    fi

    # Display directory contents
    display_directory_contents "$glob" "$depth" "$show_badges"

    # Calculate and display statistics
    local stats=$(calculate_directory_stats "$glob")
    display_summary "$stats"

    # Show additional information
    show_node_modules_info
    show_git_status

    return 0
}

# ==============================================================================
# ENTRY POINT
# ==============================================================================

# Run main function with all arguments
main "$@"
