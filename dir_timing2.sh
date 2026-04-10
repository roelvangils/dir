#!/bin/zsh

# Simple timing test
echo "Starting timing test..." >&2

# Time 1: eza command
start=$(date +%s.%N)
eza --group-directories-first --header --icons=always --long --no-user --sort modified --time-style long-iso --colour always --no-permissions --ignore-glob="node_modules|**/.DS_Store" > /dev/null
end=$(date +%s.%N)
echo "Eza execution: $(echo "scale=3; ($end - $start) * 1000" | bc)ms" >&2

# Time 2: find commands for statistics
start=$(date +%s.%N)
files=$(find . -maxdepth 1 -type f -not -name ".*" 2>/dev/null | wc -l | tr -d '[:space:]')
folders=$(find . -maxdepth 1 -type d -not -name ".*" -not -path "." 2>/dev/null | wc -l | tr -d '[:space:]')
end=$(date +%s.%N)
echo "Find commands: $(echo "scale=3; ($end - $start) * 1000" | bc)ms" >&2

# Time 3: du command for size
start=$(date +%s.%N)
size=$(find . -maxdepth 1 -type f -not -name ".*" -exec du -ch {} + 2>/dev/null | grep total$ | awk '{print $1}')
end=$(date +%s.%N)
echo "Size calculation: $(echo "scale=3; ($end - $start) * 1000" | bc)ms" >&2

# Time 4: git commands
if [[ -d ".git" ]]; then
    start=$(date +%s.%N)
    untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d '[:space:]')
    staged_count=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d '[:space:]')
    end=$(date +%s.%N)
    echo "Git commands: $(echo "scale=3; ($end - $start) * 1000" | bc)ms" >&2
fi

# Time 5: node_modules check
if [[ -d "node_modules" ]]; then
    start=$(date +%s.%N)
    node_size=$(du -sh node_modules 2>/dev/null | cut -f1)
    module_count=$(find node_modules -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d '[:space:]')
    end=$(date +%s.%N)
    echo "Node modules: $(echo "scale=3; ($end - $start) * 1000" | bc)ms" >&2
fi

echo "Done." >&2