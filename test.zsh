#!/usr/bin/env zsh
#
# Test suite for dir.
#
# The central assertion is a byte-identity gate: when no entry is recent enough
# to earn a badge, dir's reconstructed output (which asks eza for
# `<US>epoch<US>human` and strips the epoch back out) must be byte-for-byte
# identical to a plain `eza --time-style=long-iso` run. Everything else in the
# listing path is judged against that.

emulate -L zsh

typeset -g DIR=${0:A:h}/dir
typeset -g TMP=$(mktemp -d)
typeset -gi PASS=0 FAIL=0

trap 'rm -rf $TMP' EXIT

ok()   { (( PASS++ )); print -r -- "  ok   $1" }
nope() { (( FAIL++ )); print -ru2 -- "  FAIL $1"; [[ -n ${2-} ]] && print -ru2 -- "$2" }

assert_eq() {
  local name=$1 want=$2 got=$3
  if [[ $want == $got ]]; then
    ok $name
  else
    nope $name "$(diff <(print -r -- $want | cat -v) <(print -r -- $got | cat -v) | head -8)"
  fi
}

# ---------------------------------------------------------------- fixtures
mkdir -p $TMP/plain/sub/deeper $TMP/empty $TMP/hidden
print -r -- 'aaa' > $TMP/plain/a.txt
print -r -- 'bbbbbb' > $TMP/plain/b.txt
print -r -- 'c' > $TMP/plain/sub/c.md
print -r -- 'd' > $TMP/plain/sub/deeper/d.md
print -r -- 'x' > $TMP/hidden/.secret
print -r -- 'y' > $TMP/hidden/visible.txt
# A file whose timestamp eza cannot render: it prints a bare `-`, which lands
# in the Date column without our separator.
touch -t 197001010000 $TMP/plain/epoch0.bin 2>/dev/null || :
# Push everything well into the past so no badge is emitted. The directories
# must come last: writing inside one bumps its own mtime, and in tree mode eza
# lists the target directory as a row of its own.
touch -t 202001010000 $TMP/plain/**/*(DN) $TMP/hidden/*(DN)
touch -t 202001010000 $TMP/plain/sub/deeper $TMP/plain/sub $TMP/plain $TMP/hidden

typeset -a BASE=(
  --long --header --icons=always --no-user --no-permissions
  --group-directories-first --sort modified
  --ignore-glob='node_modules|.DS_Store'
  --hyperlink=always --color-scale=age --color-scale-mode=gradient
  --git
)

# strip dir's trailing summary block (blank line + summary, optional nm line)
listing_of() { print -r -- ${"$(zsh $DIR "$@")"%%$'\n'$'\n'*} }

print -r -- 'byte-identity gate (reconstruction == native long-iso)'

for label mode in \
    flat        '' \
    tree2       '--tree --level 2' \
    tree3       '--tree --level 3' ; do
  extra=(${=mode})
  dirextra=()
  [[ $mode == *level* ]] && dirextra=(--level ${extra[-1]})

  want=$(eza $BASE --colour=always $extra --time-style=long-iso -- $TMP/plain)
  [[ $mode == *tree* ]] && want=${want//└/╰}
  got=$(listing_of --color=always $dirextra $TMP/plain)
  assert_eq "colour=always $label" $want $got

  want=$(eza $BASE --colour=never $extra --time-style=long-iso -- $TMP/plain)
  [[ $mode == *tree* ]] && want=${want//└/╰}
  got=$(listing_of --color=never $dirextra $TMP/plain)
  assert_eq "colour=never  $label" $want $got
done

# --no-git removes a column; the header realignment must still hold.
want=$(eza ${BASE:#--git} --colour=always --time-style=long-iso -- $TMP/plain)
got=$(listing_of --color=always --no-git $TMP/plain)
assert_eq "colour=always no-git" $want $got

# hidden entries
want=$(eza $BASE --colour=never --all --time-style=long-iso -- $TMP/hidden)
got=$(listing_of --color=never --all $TMP/hidden)
assert_eq "colour=never  --all" $want $got

print -r -- ''
print -r -- 'behaviour'

# --no-badges must agree with the badge path when nothing is recent
a=$(listing_of --color=never $TMP/plain)
b=$(listing_of --color=never --no-badges $TMP/plain)
assert_eq "--no-badges matches badge path" $a $b

# badges actually appear for a fresh file
: > $TMP/plain/fresh.txt
out=$(zsh $DIR --color=never $TMP/plain)
if [[ $out == *'[JUST NOW]'* ]]; then ok 'fresh file gets JUST NOW'
else nope 'fresh file gets JUST NOW' "$out"; fi
rm -f $TMP/plain/fresh.txt

# counts and summary
out=$(zsh $DIR --color=never $TMP/plain)
if [[ $out == *'Found '*' files'*' and just one folder.'* ]]; then
  ok 'summary reports files and folders'
else nope 'summary reports files and folders' "$out"; fi

# hidden entries change the counts
vis=$(zsh $DIR --color=never $TMP/hidden)
hid=$(zsh $DIR --color=never --all $TMP/hidden)
if [[ $vis == *'just one file'* && $hid == *'2 files'* ]]; then
  ok '--all is reflected in the counts'
else nope '--all is reflected in the counts' "visible: $vis"$'\n'"all: $hid"; fi

# empty directory
out=$(zsh $DIR --color=never $TMP/empty)
[[ $out == 'This folder is empty.' ]] && ok 'empty directory' || nope 'empty directory' "$out"

# glob filter
out=$(zsh $DIR --color=never --glob '*.txt' $TMP/plain)
if [[ $out == *a.txt* && $out == *b.txt* && $out != *sub* ]]; then
  ok '--glob filters the listing'
else nope '--glob filters the listing' "$out"; fi

out=$(zsh $DIR --color=never --glob 'nothing-matches-this' $TMP/plain 2>&1); rc=$?
(( rc == 1 )) && ok 'unmatched glob exits 1' || nope 'unmatched glob exits 1' "rc=$rc $out"

# default path is the cwd
out=$( cd $TMP/plain && zsh $DIR --color=never )
[[ $out == *a.txt* ]] && ok 'defaults to cwd' || nope 'defaults to cwd' "$out"

print -r -- ''
print -r -- 'cli'

zsh $DIR --help >/dev/null && ok '--help exits 0' || nope '--help exits 0'
[[ $(zsh $DIR --version) == 'dir '* ]] && ok '--version prints a version' || nope '--version'

zsh $DIR --bogus >/dev/null 2>&1; (( $? == 2 )) && ok 'unknown flag exits 2' || nope 'unknown flag exits 2'
zsh $DIR /definitely/not/here >/dev/null 2>&1; (( $? == 1 )) && ok 'bad path exits 1' || nope 'bad path exits 1'
zsh $DIR --level x >/dev/null 2>&1; (( $? == 2 )) && ok 'non-numeric --level exits 2' || nope 'non-numeric --level exits 2'
zsh $DIR $TMP/plain $TMP/empty >/dev/null 2>&1; (( $? == 2 )) && ok 'two paths exit 2' || nope 'two paths exit 2'

# autoload form: first call and subsequent calls must both work
out=$(zsh -f -c "fpath=(${0:A:h} \$fpath); autoload -Uz dir; dir --color=never $TMP/plain; dir --color=never $TMP/plain" 2>&1)
if [[ ${#${(f)out}} -gt 10 && $out == *a.txt* ]]; then
  ok 'autoload form works on first and later calls'
else nope 'autoload form' "$out"; fi

# sourcing must define without running
out=$(zsh -f -c "source ${0:A:h}/dir; print MARKER" 2>&1)
[[ $out == 'MARKER' ]] && ok 'sourcing does not auto-run' || nope 'sourcing does not auto-run' "$out"

print -r -- ''
print -r -- "passed $PASS, failed $FAIL"
(( FAIL == 0 ))
