#!/bin/zsh

if [ -z "$(ls -A '.')" ]; then
    echo "This folder is empty."
    return
fi

_EM_() {
    text="$1"

    # If the text is empty, just return
    if [ -z "$text" ]; then
        return
    fi

    # Print the italic text
    echo -ne "\033[3;90m${text}\033[0m"
}

_STRONG_() {
    text="$1"

    # If the text is empty, just return
    if [ -z "$text" ]; then
        return
    fi

    # Print the bold text
    echo -e "\033[1m${text}\033[0m"
}

_A_() {
    url="$1"
    text="$2"

    # If the text is empty, use the URL as the text
    if [ -z "$text" ]; then
        text="$url"
    fi

    # Print the clickable link
    echo -e "\033]8;;${url}\a${text}\033]8;;\a"
}

_HR_() { # Print a horizontal rule
    echo -e "\033[38;5;232m$(printf "%$(tput cols)s" "" | tr ' ' '─')\033[0m"
}

glob=$1
if [ "$glob" = "h" ]; then
    # Show only hidden files
    eza \
        --all \
        --group-directories-first \
        --header \
        --icons \
        --long \
        --no-user \
        --sort modified \
        --time-style long-iso \
        --colour always \
        --ignore-glob="node_modules|**/.DS_Store|.|.." \
        .*
else
    # Original behavior
    eza *$glob* \
        --all \
        --group-directories-first \
        --header \
        --icons \
        --long \
        --tree \
        --level 2 \
        --no-user \
        --no-permissions \
        --sort modified \
        --tree \
        --level 0 \
        --time-style long-iso \
        --colour always \
        --ignore-glob="node_modules|**/.DS_Store"
fi

files=$(find . -maxdepth 1 -type f -name "*$glob*" -not -name ".*" | wc -l | tr -d '[:space:]')
folders=$(find . -maxdepth 1 -type d -name "*$glob*" -not -name ".*" | wc -l | tr -d '[:space:]')
depth=$2

if [ -z "$depth" ]; then
    depth=1
fi

function num_to_word {
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
    *) echo $1 ;;
    esac
}
if [ $files -eq 1 ]; then
    output1="just one file"
elif [ $files -eq 0 ]; then
    output1="no files"
else
    output1="$(num_to_word $files) files"
fi

if [ $folders -eq 1 ]; then
    output2="and just one folder "
elif [ $folders -eq 0 ]; then
    output2=""
else
    output2="and $(num_to_word $folders) folders "
fi

# Define an array of number words
folder="$(pwd)"
size=$(du -shc ./*(.D) | tail -n 1 | awk '{print $1}')
summary="    Found $output1 (± $size) $output2"

echo -e "\n$(_EM_ "${summary}")"

# Check if node_modules folder exists and show info if it does
if [ -d "node_modules" ]; then
    node_modules_size=$(du -sh node_modules 2>/dev/null | cut -f1)
    module_count=$(find node_modules -maxdepth 1 -type d | wc -l | tr -d '[:space:]')
    module_count=$((module_count - 1)) # Subtract 1 to exclude the node_modules directory itself
    echo -e "$(_EM_ "    The ")$(_A_ "file://$(pwd)/node_modules" "$(_EM_ "node_modules")")$(_EM_ " folder ($module_count modules, ±$node_modules_size) is not listed.")"
fi

# Check if this is a git repository and show git status
if [ -d ".git" ]; then
    untracked_count=$(git ls-files --others --exclude-standard | wc -l | tr -d '[:space:]')
    staged_count=$(git diff --cached --name-only | wc -l | tr -d '[:space:]')

    # Build the message parts
    messages=()

    # Add untracked files message if count > 0
    if [ $untracked_count -gt 0 ]; then
        if [ $untracked_count -eq 1 ]; then
            messages+=("$(num_to_word $untracked_count) untracked file")
        else
            messages+=("$(num_to_word $untracked_count) untracked files")
        fi
    fi

    # Add staged files message if count > 0
    if [ $staged_count -gt 0 ]; then
        if [ $staged_count -eq 1 ]; then
            messages+=("$(num_to_word $staged_count) staged file")
        else
            messages+=("$(num_to_word $staged_count) staged files")
        fi
    fi

    # Only display if there's something to show
    if [ ${#messages[@]} -gt 0 ]; then
        # Join messages with comma
        output=$(printf "%s, " "${messages[@]}")
        output=${output%, } # Remove trailing comma and space
        # Capitalize the first letter
        output="$(echo ${output:0:1} | tr '[:lower:]' '[:upper:]')${output:1}"
        echo -e "$(_EM_ "    $output")"
    fi
fi
