#!/usr/bin/env zsh
#
# Benchmark dir against a directory. Usage: ./bench.zsh [PATH] [RUNS]
#
# Reports wall-clock milliseconds per run, plus the eza-only floor so it is
# clear how much of the time is the shell and how much is eza itself.

emulate -L zsh
zmodload zsh/datetime

local target=${1:-$PWD}
integer runs=${2:-5}
local self=${0:A:h}

timeit() {
  local label=$1; shift
  local -F start end
  integer i
  start=$EPOCHREALTIME
  for (( i = 1; i <= runs; i++ )); do "$@" >/dev/null 2>&1; done
  end=$EPOCHREALTIME
  printf '  %-28s %7.1f ms\n' $label $(( (end - start) * 1000 / runs ))
}

local -a EZA=(
  eza --long --header --icons=always --no-user --no-permissions
  --group-directories-first --sort modified --colour=always
  --ignore-glob='node_modules|.DS_Store' --hyperlink=always
  --color-scale=age --color-scale-mode=gradient --git
  --time-style=long-iso
)

print -r -- "target: $target"
print -r -- "entries: $(print -rl -- $target/*(DN) | wc -l | tr -d ' ')   runs: $runs"
print -r -- ''

for depth in 0 1 2 3; do
  local -a extra=() dextra=()
  if (( depth > 0 )); then
    extra=( --tree --level $depth )
    dextra=( --level $depth )
  fi
  integer lines=$( $EZA $extra -- $target 2>/dev/null | wc -l )
  print -r -- "depth $depth  (${lines} lines)"
  timeit 'eza alone (floor)'  $EZA $extra -- $target
  timeit 'dir'                zsh $self/dir --color=always $dextra $target
  timeit 'dir --no-badges'    zsh $self/dir --color=always --no-badges $dextra $target
  print -r -- ''
done
