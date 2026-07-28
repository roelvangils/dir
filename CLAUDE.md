# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A single-file Zsh utility that wraps [`eza`](https://github.com/eza-community/eza) to add
relative-time badges, a summary line, and Git awareness. The whole design is organised
around one constraint: **zero forks per listed entry**.

## Layout

| File | Role |
|---|---|
| `dir` | The implementation. Works as a script *and* as an `autoload -Uz` function. |
| `dir.sh` | Symlink to `dir`, kept so pre-existing aliases don't break. |
| `test.zsh` | Test suite. 24 assertions, no dependencies beyond zsh + eza. |
| `bench.zsh` | Benchmarks `dir` against the `eza`-only floor at depths 0–3. |

## Commands

```bash
zsh ./test.zsh              # run the tests
zsh ./bench.zsh [PATH] [N]  # benchmark
zsh -n dir                  # syntax check
```

## How it works

### The epoch trick

Badges need a Unix timestamp; `eza` renders a human date. Rather than parsing the rendered
date back into an epoch (the old code forked `date -j -f` per row), `eza` is asked for
both at once:

```zsh
--time-style="+${DIR_SEP}%s${DIR_SEP}%Y-%m-%d %H:%M"
```

`DIR_SEP` is ASCII Unit Separator (`$'\x1f'`). The epoch is then stripped with plain
parameter expansion — no subprocesses:

```zsh
prefix=${line%%$DIR_SEP*}; rest=${line#*$DIR_SEP}; epoch=${rest%%$DIR_SEP*}
line="${prefix}${rest#*$DIR_SEP}"
```

**This is safe only because no column before Date can contain user data.** With the
current flags the only earlier column is Size. Adding `--git-repos`, `-@`/`--extended`, or
`--context` would put user-controlled text ahead of the date and silently break the
"first separator is ours" rule. There is a comment to this effect at the `eza_args` array
— heed it.

### Column realignment

`eza` sizes the Date column to the widest *rendered* value. Because our format is 12
characters wider than the final output, every row we *don't* rewrite — the header, and any
row whose timestamp `eza` couldn't render (it prints a bare `-`) — ends up over-padded by
exactly `strip` characters. Those rows are recorded in `undated` during the loop and fixed
afterwards by collapsing the first run of `strip + 1` spaces. No other run in those rows
is longer than a single-space column separator, which is what makes that safe.

This is the fragile part of the file. `test.zsh` guards it with a byte-identity assertion
against native `eza --time-style=long-iso` output.

### Other performance decisions

- **Slurp, don't stream.** `lines=("${(@f)$(eza …)}")` plus a `for` loop beats
  `while read` by ~2× on large trees. Output is buffered into an **array** and emitted
  with one `print -r -- ${(F)out}`; string `+=` accumulation is O(n²).
- **`out=( ${out//└/╰} )` is per-element on purpose.** It is ~5× faster than one
  substitution over the joined string. Do not "optimise" it.
- **Counting uses glob qualifiers** (`(.N)`, `(/N)`, `(D…)` under `--all`), not
  `find | awk`.
- **Sizes use `zstat +size`**, not `du`.
- **Git and `du -sk node_modules` run on background fds** opened with `exec {fd}< <(…)`
  *before* `eza` runs, so they overlap it instead of being serialised after it. No temp
  files. Both fds are closed in an `always` block.
- **eza prints nothing when given no path operand and stdin is not a TTY.** Every code
  path passes an explicit operand. Do not reintroduce a bare `eza`.

### Fallbacks

Capability handling is optimistic: if `eza` rejects the `+FORMAT` time style (rc != 0 or
empty output), the listing is re-run with `--time-style=long-iso` and badges are silently
dropped. There is deliberately no upfront probe — it would cost a fork on every run to
guard a condition that is false on every supported version.

## Conventions

- `emulate -L zsh` at the top of `dir()` so user `setopt`s can't change behaviour.
- `print -r --`, never `echo -e` — `echo -e` mangles filenames containing backslashes.
- Parse numeric options into a **string** first and validate with `[[ $x == <-> ]]`.
  Assigning directly to an `integer` silently arithmetic-evaluates `x` to `0`.
- Helper functions are `dir::`-prefixed so the autoload form doesn't pollute the global
  namespace.

## Testing

`test.zsh` fixtures backdate files with `touch -t`. Note that writing inside a directory
bumps *its* mtime, and in tree mode `eza` lists the target directory as its own row — so
directories must be backdated last, after their contents.
