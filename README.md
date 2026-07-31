# dir — enhanced directory listing

A Zsh front end for [`eza`](https://github.com/eza-community/eza) that adds relative-time
badges, a one-line summary of what's in the folder, and Git awareness — without being slow
about it.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Shell](https://img.shields.io/badge/shell-zsh-green.svg)
![Dependencies](https://img.shields.io/badge/requires-eza-orange.svg)

## Why `dir`?

`eza` already lists files beautifully. `dir` adds the things you'd otherwise squint at a
timestamp column to work out:

- **Time badges** — `JUST NOW`, `12 MINS AGO`, `TODAY`, `YESTERDAY`, colour-coded, so the
  file you were just editing is obvious.
- **A summary line** — file count, folder count, total size, and how many files are
  untracked or staged, in one sentence.
- **`node_modules` sanity** — kept out of the listing, reported as a module count and a
  size. Run `dir` *inside* `node_modules` and you get `npm ls` instead.
- **Speed** — see below.

## Performance

The listing is built with zero forks per entry. `eza` is asked to render the mtime as
`<US>epoch<US>human` via a chrono `--time-style` format, so the epoch the badges need
arrives for free and is stripped back out with plain parameter expansion. The previous
implementation forked `sed` and `date` for *every listed row*, and the summary ran a
`find | awk` pipeline with a `test -f` fork per entry.

Measured on an M5 Max (zsh 5.9, eza 0.23.5), running as a script:

| Case | Before | After | |
|---|---|---|---|
| 153-entry directory | 660 ms | 20 ms | **33×** |
| 7,565-line `--level 3` tree | 31,400 ms | 344 ms | **91×** |
| Summary counting alone | 380 ms | 1 ms | **380×** |

`./bench.zsh [PATH] [RUNS]` reproduces these and reports the `eza`-only floor alongside,
so you can see how much of the remaining time is `eza` itself.

## Installation

`eza` 0.23 or newer is required:

```bash
brew install eza          # macOS
cargo install eza         # anywhere with Rust
```

Then clone and pick one of the two ways to use it:

```bash
git clone https://github.com/roelvangils/dir.git ~/repos/dir
```

**As a shell function (recommended).** Skips starting a second `zsh` on every call, which
is worth roughly 3 ms out of a 20 ms run:

```zsh
# ~/.zshrc
fpath=(~/repos/dir $fpath)
autoload -Uz dir
```

**As a script.** `dir.sh` is a symlink to `dir`, so older aliases keep working:

```zsh
alias dir="~/repos/dir/dir"
```

## Usage

### Filters

The common cases are bare words — no dashes, no flags to remember:

| Word | Shows |
|---|---|
| `h` | only hidden entries |
| `d` | only folders |
| `f` | only files |
| `n` | only entries created today |
| `m` | only entries modified today |
| `500k` `1m` `2g` | only entries larger than that (`k`/`m`/`g`, powers of 1024) |
| anything else | only names containing that word |

They combine in any order, ANDed together:

```bash
dir h                # hidden entries
dir d                # folders
dir 10m              # anything over 10 MiB
dir d 10m            # folders over 10 MiB
dir f n              # files created today
dir h config         # hidden entries whose name contains 'config'
dir config h         # identical — order never matters
```

### Options

```
dir [OPTIONS] [FILTER...] [PATH]

  -L, --level DEPTH    show a tree DEPTH levels deep (0 = flat, the default)
  -a, --all            include hidden entries, in both the listing and counts
  -g, --glob PATTERN   list only entries whose name matches PATTERN
  -B, --no-badges      disable the relative-time badges
      --no-git         omit the per-file git status column
      --color WHEN     always | never | auto (default: auto)
  -h, --help           show this help
  -V, --version        show the version
```

```bash
dir                       # the current directory
dir ~/repos               # somewhere else
dir --level 2             # two-level tree
dir --glob '*.md'         # a real glob, rather than a substring
dir --no-badges ~/repos   # plain listing, no badges
```

Filter words win over paths, so a directory named `h` is only reachable as
`dir ./h` or `dir --glob h`. Filters apply to the listed directory only — they
are not recursive, which matches what the listing shows.

### Output

```
Size Date Modified    Git Name
2.6k 2026-07-28 17:33  -N 󰂺 README.md            JUST NOW
5.7k 2026-07-28 16:58  --  dir                  35 MINS AGO
1.1k 2026-07-28 09:12  M-  .gitignore           TODAY
245B 2026-07-27 16:30  -- 󰉋 src                  YESTERDAY

Found 16 files (±95k) and 1 folder. 1 file is untracked.
```

File names are OSC-8 hyperlinks, so they're clickable in terminals that support it. The
date column is tinted on an age gradient, which gives you a sense of recency on rows too
old to earn a badge.

## Notes on behaviour

- **Badges use calendar days, not elapsed seconds.** A file touched at 23:50 yesterday
  reads `YESTERDAY` (or `20 MINS AGO`) at 00:10 — not `TODAY`. Day boundaries go through
  `mktime`, so they stay correct across a DST change.
- **Untracked counts come from `git status --porcelain -unormal`**, which collapses an
  untracked directory to a single entry — the same number `git status` shows you.
- **Hidden entries are all-or-nothing.** `--all` affects the listing and the counts
  together, so the summary can't contradict what's on screen. Note that `h` and `--all`
  differ: `h` shows *only* hidden entries, `--all` shows them *alongside* the rest.
- **`n` needs file birth time**, which zsh cannot read natively, so it costs one `stat`
  call — and only when you actually use it. macOS reports birth time; on systems that
  don't, `n` falls back to modified-today.
- **Filtering with `d` over many git repositories is slower than it looks.** Each matched
  directory becomes a separate operand, and eza opens each one as its own git root —
  `dir d` across 150 repos takes ~150 ms versus ~9 ms with `--no-git`.
- `--no-optional-locks` is passed to Git so a listing never rewrites the index underneath
  a running editor or language server.

## Requirements

- **zsh** — the script uses zsh-only features throughout.
- **eza** ≥ 0.23. Older versions that reject a `+FORMAT` time style still work; you just
  don't get badges.
- **git** and **npm** are optional; their sections are skipped when absent.

## Development

```bash
zsh ./test.zsh      # 24 assertions
zsh -n dir          # syntax check
zsh ./bench.zsh     # benchmarks
```

The central test is a byte-identity gate: with no recent files, `dir`'s reconstructed
output must be byte-for-byte identical to a plain `eza --time-style=long-iso` run, across
flat/tree/colour/`--git`/`--all` combinations. If a future change breaks the column
arithmetic, that test fails first.

## License

MIT — see [LICENSE](LICENSE).

## Author

Created by Roel Van Gils.
