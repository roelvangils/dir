#!/bin/zsh

# dir - Simple enhanced directory listing with eza

# Exit if directory is empty
if [[ -z "$(ls -A '.' 2>/dev/null)" ]]; then
    echo "This folder is empty."
    exit 0
fi

# Check if eza is installed
if ! command -v eza &>/dev/null; then
    echo "Error: eza is not installed. Please install it with: brew install eza" >&2
    exit 1
fi

# Text formatting functions
_EM_() {
    [[ -z "$1" ]] && return
    echo -ne "\033[3;90m${1}\033[0m"
}

# Format number in white (not bold) within italic text
_NUM_() {
    echo -ne "\033[97m${1}\033[3;90m"
}

_A_() {
    local url="$1"
    local text="${2:-$url}"
    echo -e "\033]8;;${url}\a${text}\033]8;;\a"
}

# Badge formatting function
_BADGE_() {
    local text="$1"
    local color="$2"
    echo -ne "${color}\033[1m ${text} \033[0m"
}

# Calculate time difference and return appropriate badge
get_time_badge() {
    local file_time="$1"
    local current_time="$2"
    
    local diff=$((current_time - file_time))
    local minutes=$((diff / 60))
    local hours=$((diff / 3600))
    local days=$((diff / 86400))
    
    if [[ $minutes -lt 1 ]]; then
        echo "JUST NOW"
    elif [[ $minutes -lt 60 ]]; then
        if [[ $minutes -eq 1 ]]; then
            echo "1 MIN AGO"
        else
            echo "$minutes MINS AGO"
        fi
    elif [[ $days -eq 0 ]]; then
        echo "TODAY"
    elif [[ $days -eq 1 ]]; then
        echo "YESTERDAY"
    else
        echo ""
    fi
}

# Process eza output to add time badges
process_eza_output() {
    local line="$1"
    local show_badges="$2"
    local current_time="$3"
    
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
    
    # Extract timestamp from eza output
    local clean_line=$(echo "$line" | sed -E 's/\[[0-9;]+m//g')
    local timestamp=""
    
    # Match the date-time pattern (YYYY-MM-DD HH:MM)
    if [[ "$clean_line" =~ '([0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{2}:[0-9]{2})' ]]; then
        timestamp="${match[1]}"
    fi
    
    # If we found a timestamp, calculate badge
    if [[ -n "$timestamp" ]]; then
        local file_time
        if [[ "$OSTYPE" == "darwin"* ]]; then
            file_time=$(date -j -f "%Y-%m-%d %H:%M" "$timestamp" "+%s" 2>/dev/null)
        else
            file_time=$(date -d "$timestamp" "+%s" 2>/dev/null)
        fi
        
        if [[ -n "$file_time" ]]; then
            local badge=$(get_time_badge "$file_time" "$current_time")
            
            if [[ -n "$badge" ]]; then
                # Choose color based on badge type (reversed scheme)
                local color
                case "$badge" in
                    "JUST NOW")
                        color="\033[38;5;196;107m"  # Red text, white background
                        ;;
                    *"MIN"*|*"MINS"*)
                        color="\033[38;5;214;40m"  # Orange text, black background
                        ;;
                    "TODAY")
                        color="\033[38;5;226;40m"  # Yellow text, black background
                        ;;
                    "YESTERDAY")
                        color="\033[38;5;244;107m"  # Gray text, white background
                        ;;
                esac
                
                echo -e "${line} $(_BADGE_ "$badge" "$color")"
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

# Parse arguments
show_badges=true
glob=""
depth="0"  # Default to 0 (no tree)

# Process all arguments
for arg in "$@"; do
    if [[ "$arg" == "--no-badges" ]]; then
        show_badges=false
    elif [[ "$arg" =~ ^[0-9]+$ ]]; then
        depth="$arg"
    elif [[ "$arg" == "h" ]]; then
        glob="h"
    elif [[ -z "$glob" ]]; then
        glob="$arg"
    fi
done

# Build eza command
eza_args=(
    --group-directories-first
    --header
    --icons=always
    --long
    --no-user
    --sort modified
    --time-style long-iso
    --colour always
    --no-permissions
    --ignore-glob="node_modules|**/.DS_Store"
)

# Add tree arguments if depth > 0
if [[ "$depth" -gt 0 ]]; then
    eza_args+=(--tree --level "$depth")
fi

# Get current time for badge calculations
current_time=$(date +%s)

# Run eza and process output
if [[ "$glob" == "h" ]]; then
    eza --all "${eza_args[@]}" .* | sed 's/└/╰/g' | while IFS= read -r line; do
        process_eza_output "$line" "$show_badges" "$current_time"
    done
elif [[ -n "$glob" ]]; then
    eza "${eza_args[@]}" *"$glob"* | sed 's/└/╰/g' | while IFS= read -r line; do
        process_eza_output "$line" "$show_badges" "$current_time"
    done
else
    eza "${eza_args[@]}" | sed 's/└/╰/g' | while IFS= read -r line; do
        process_eza_output "$line" "$show_badges" "$current_time"
    done
fi

# Calculate statistics
if [[ -n "$glob" && "$glob" != "h" ]]; then
    files=$(find . -maxdepth 1 -type f -name "*$glob*" -not -name ".*" 2>/dev/null | wc -l | tr -d '[:space:]')
    folders=$(find . -maxdepth 1 -type d -name "*$glob*" -not -name ".*" -not -path "." 2>/dev/null | wc -l | tr -d '[:space:]')
else
    files=$(find . -maxdepth 1 -type f -not -name ".*" 2>/dev/null | wc -l | tr -d '[:space:]')
    folders=$(find . -maxdepth 1 -type d -not -name ".*" -not -path "." 2>/dev/null | wc -l | tr -d '[:space:]')
fi

# Calculate size of files only in current directory (not subdirectories)
if [[ $files -gt 0 ]]; then
    # Use find to get only non-hidden files and sum their sizes
    size=$(find . -maxdepth 1 -type f -not -name ".*" -exec du -ch {} + 2>/dev/null | grep total$ | awk '{print $1}')
    # If no total line (only one file), get the size directly
    if [[ -z "$size" ]]; then
        size=$(find . -maxdepth 1 -type f -not -name ".*" -exec du -h {} + 2>/dev/null | awk '{print $1}' | head -1)
    fi
else
    size="0B"
fi

# Build summary message
if [[ $files -eq 0 ]]; then
    file_msg="no files"
elif [[ $files -eq 1 ]]; then
    file_msg="just one file"
else
    file_msg="$(_NUM_ $files) files"
fi

folder_msg=""
if [[ $folders -gt 0 ]]; then
    if [[ $folders -eq 1 ]]; then
        folder_msg=" and just one folder"
    else
        folder_msg=" and $(_NUM_ $folders) folders"
    fi
fi

# Build status message - we'll handle formatting when we print
summary="Found $file_msg (±$size)$folder_msg"

# Add git status if in a repository
if [[ -d ".git" ]]; then
    untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d '[:space:]')
    staged_count=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d '[:space:]')
    
    git_msg=""
    
    if [[ $untracked_count -gt 0 ]]; then
        if [[ $untracked_count -eq 1 ]]; then
            git_msg="$(_NUM_ $untracked_count) file is untracked"
        else
            git_msg="$(_NUM_ $untracked_count) files are untracked"
        fi
    fi
    
    if [[ $staged_count -gt 0 ]]; then
        staged_msg=""
        if [[ $staged_count -eq 1 ]]; then
            staged_msg="$(_NUM_ $staged_count) file is staged"
        else
            staged_msg="$(_NUM_ $staged_count) files are staged"
        fi
        
        if [[ -n "$git_msg" ]]; then
            git_msg="$git_msg and $staged_msg"
        else
            git_msg="$staged_msg"
        fi
    fi
    
    if [[ -n "$git_msg" ]]; then
        summary="$summary. $git_msg"
    fi
fi

# Add final period if not already there
[[ "$summary" != *. ]] && summary="$summary."

echo -e "\n$(_EM_ "$summary")"

# Add node_modules info if it exists (on new line)
if [[ -d "node_modules" ]]; then
    node_size=$(du -sh node_modules 2>/dev/null | cut -f1)
    module_count=$(find node_modules -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d '[:space:]')
    module_count=$((module_count - 1))
    
    node_msg="The $(_A_ "file://$(pwd)/node_modules" "node_modules") folder ($(_NUM_ $module_count) modules, ±$node_size) is not listed."
    echo -e "$(_EM_ "$node_msg")"
fi