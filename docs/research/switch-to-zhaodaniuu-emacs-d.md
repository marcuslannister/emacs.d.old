# Switch from this config (A) to zHaOdANiuu/.emacs.d (B)

Date: 2026-11-09. Method: read B at `origin/main` (`43e8334`, 2026-10-31) from a `git archive` extract in a new temp dir. I did not load or run any B file, and I did not pull or check out B's clone. I read A's init files, local layer, tests, CI, and agent files. I read Emacs 31.1 `startup.el`, `server.el`, `package.el`, `use-package-core.el`, `etc/NEWS`, and the Emacs manual. I ran `emacs -Q --batch` to print defaults and docstrings. I read variable values in the running A session through Anvil (read-only). I sent HTTP HEAD requests to the package archives. I used the GitHub API for B's metadata. I did not change A.

- A = `~/Projects/emacs.d`. `~/.emacs.d` is a symlink to it. A paths are relative to that root.
- B = `zHaOdANiuu/.emacs.d`. B paths and line numbers are from `origin/main`.
- C1 = the earlier note, `docs/research/emacs-config-comparison-zhaodaniuu.md` (2026-10-09, based on B `e2d1f09`). This note does not repeat C1. Section 8 lists the C1 claims that changed.
- "Not confirmed" marks a claim I could not verify in a primary source.

## 1. Recommendation

Do not replace A with B. First run B side by side for a trial with `--init-directory` (path d), and keep `~/.emacs.d` on A. After the trial, keep A and borrow B's best ideas (path c). Fork B and port A's local layer into it (path b) only if the trial shows that you prefer B's base, because the port is large.

| Path | Cost | Risk | Rollback |
|---|---|---|---|
| (a) Full replace | Low to do. High in lost features | High: Anvil MCP, Hel, org-gtd, case guard, PATH, and auto save stop at once | Point the symlink back. A's state stays in place |
| (b) Fork B, port A's layer | Large: about 4,000 lines of local layer, plus the base parts it uses | Medium: B's defaults conflict with A's layer in at least 5 places | Point the symlink back. Old A stays intact |
| (c) Keep A, borrow ideas | Small per item | Low: one commit per item, tested by `./test-startup.sh` | `git revert` |
| (d) Trial with `--init-directory` | Low | Low, if you keep B away from `~/org` | Quit B. Move the trial dir to the Trash |

## 2. Top blockers for a full switch

1. **Anvil MCP stops.** Both MCP clients run `~/.emacs.d/anvil-stdio.sh` (Claude: `~/.claude.json`, entries `anvil` and `anvil-emacs-eval`; Codex: `~/.codex/config.toml:35-43`, where `anvil-stdio.sh` resolves to the same file on PATH). That file is gitignored in A (`.gitignore:76`). Anvil installs it to `user-emacs-directory` by default (`external-packages/anvil.el/anvil-server.el:87`). The bridge talks to Emacs through `emacsclient`, so it needs a running server. A starts the server at `init.el:207-209` and Anvil at `lisp/init-local.el:530-537` and `lisp/init-local-ai.el:50-51`. B has no `server-start` and no Anvil (`rg -i` for `anvil`, `mcp`, `server-start`, and `server-mode` in B finds only `live-server-start` and `gnus-server-mode`).
2. **`~/org` loses its guards.** A guards `~/org` against silent upcasing (`lisp/init-local-case-guard.el:83,264-272`). That folder has no Git history and syncs through Syncthing (`lisp/init-local-case-guard.el:8`). B has no guard. B binds `M-u` and `M-l` to commands that change the case of the whole active region (`user-lisp/init-keybind.el:75-76,126-136`). The command calls `upcase-region` as a function, so the `disabled` property does not stop it (A states the same rule at `lisp/init-local-hel.el:228-230`). B also deletes trailing whitespace on every save in every buffer (`user-lisp/init-display.el:194-197`). B's capture templates write into `org-directory`, and the default value is `~/org` (batch print). One target, `~/org/journal.org`, already exists (`user-lisp/init-lang.el:784-795`).
3. **No PATH import.** The running Emacs is `/Applications/Emacs.app` with parent PID 1 (`launchd`). `launchctl getenv PATH` is empty, and the app bundle has no `LSEnvironment` PATH (PlistBuddy). A finds `rg`, `fd`, and `git` in `/run/current-system/sw/bin` and `herdr` in `/opt/homebrew/bin` (live session) through `exec-path-from-shell` (`lisp/init-exec-path.el:12-15`). B imports PATH on Windows only (`early-init.el:120-142`). Herdr loads in A only when `herdr` is on `exec-path` (`lisp/init-local-herdr.el:151`).
4. **No Hel, no leader.** A's daily editing model is Hel with 144 leader bindings (`lisp/init-local-hel.el:39-235`). B has no modal package. Its Viper layer is off by default (`nn.el:29-32`, `user-lisp/init-editor.el:474-476`). B rebinds `C-a`, `C-v`, `C-z`, `M-w`, and `C-w` globally (`user-lisp/init-keybind.el:49-50,63-65`).
5. **GTD pipeline and session habits go.** B has no org-gtd, Denote, Vulpea, auto save, or persistent undo (section 4). A saves buffers automatically (`lisp/init-local.el:97-115`). B does not (`rg auto-save-visited` in B: only a remote-file option at `user-lisp/init-tools.el:498`).
6. **B is a personal config with weak maintenance signals.** 41 of 44 commits have the message "Fix some known issues." (GitHub API). B has no tests and no CI (file list of `origin/main`). The README names files that do not exist (section 3). B hard-codes its author's name and mail address (`early-init.el:71-72`) and mail account (`user-lisp/init-www.el:118-121`).

These items are **not** blockers (checked):

| Item | Result | Source |
|---|---|---|
| China-only package archives | Both mirrors answer HTTP 200 in 0.26-0.73 s from here. GNU ELPA and MELPA also answer 200 | HEAD requests to `early-init.el:152-154` URLs and their `archive-contents` |
| `lexical-binding` default set to nil | No-op. The Emacs 31.1 top-level default is already nil | `early-init.el:7`; `etc/NEWS:3805-3810`; `emacs -Q --batch` print; live A session also nil |
| Missing macOS modifier keys | Emacs 31.1 defaults are option=meta, command=super. That is A's effective setting | batch print of `mac-option-modifier`, `mac-command-modifier`; A `lisp/init-local-macos.el:6-7`; live A session |
| Windows-first settings | Gated by `_WIN32` or `boundp 'w32-...`, so they do not apply here | `early-init.el:36-38,63-66,120-142` |
| Fonts | B's first default font, IBM Plex Mono, is installed. So are JetBrains Mono, LXGW WenKai Mono, and Symbols Nerd Font Mono | `init.el:25-82`; `find-font` in the live session |

## 3. What B is now

| Fact | Value | Source |
|---|---|---|
| Purpose | "a personal, batteries-included Emacs configuration for GNU Emacs 31 and newer" | `README.org:14-15` |
| Install | `git clone` into `~/.emacs.d`. No bootstrap step | `README.org:78-87` |
| Emacs version | 31 and newer only | `README.org:65`; `user-lisp-directory` is new in 31.1 (`startup.el:1202-1223`) |
| License | GPL-3.0 | `LICENSE`; GitHub license API |
| Popularity | 30 stars, 2 forks, 0 watchers, 0 open issues | GitHub API, 2026-11-09 |
| Age and cadence | Repo created 2026-06-08. 44 commits by author date: 1 in May, 17 in Aug, 16 in Sep, 10 in Oct. Last push 2026-10-31 | GitHub API |
| Commit messages | 41 of 44 are "Fix some known issues." | GitHub commits API |
| Tests and CI | None | `git ls-tree origin/main` |
| Own Git packages | `color-picker.el` (no license file: license API returns 404), `magit-fast` (GPL-3.0), `simpcc-mode` (GPL-3.0), all `:rev :newest` | `user-lisp/init-display.el:247`, `user-lisp/init-tools.el:233`, `user-lisp/init-lang.el:275`; GitHub API |
| Packages from archives | About 28 forms install from an archive, because `use-package-always-ensure` is t (`early-init.el:159`). The less common ones (`minibuffer-frame`, `material-icons`, `ghostel`, `calfw`, `telega`, `citre`) have MELPA recipes | awk scan of `use-package` forms without `:ensure nil`; `melpa/melpa` recipes via GitHub API |

README drift: the README says state lives in `.nn/` and settings in `user-lisp/init-def.el` (`README.org:19,85`). The code uses `var/` (`nn.el:8`), and `init-def.el` does not exist. The README lists translation (`README.org:37`), but the translate commands are empty stubs (`user-lisp/init-keybind.el:231-235`).

Code that does not work as written:

- `nn-open-in-external-app` builds its list with `'(,(buffer-file-name))` (`nn.el:167`). With a plain quote, the comma is not evaluated. In batch, `(car '(,(buffer-file-name)))` returns `(\, (buffer-file-name))`, not a file name.
- `nn-proxy-enable` puts `(format ...)` inside a quoted list and uses `setq-local` (`nn.el:144-151`). So the proxy strings are never formatted, and the setting applies to one buffer only.

### Changes from `e2d1f09` to `origin/main` (6 commits, 2026-10-08 to 2026-10-31)

| Change | Meaning | Source |
|---|---|---|
| `init-debug`, `init-vc`, `init-terminal`, `init-utils` merged into new `init-tools.el` | 11 modules became 8 | `init.el:16-23`; diff stat: 4 files deleted, `user-lisp/init-tools.el` +532 |
| Own packages moved to `user-lisp/local/` | `prepare-user-lisp` adds subdirs to `load-path` (`startup.el:1268-1275`) | diff stat (renames) |
| `nn-directory` now `user-emacs-directory` + `var/`, made if missing | State follows `--init-directory`. At `e2d1f09` it was always `~/.emacs.d/var/` | `nn.el:8,117-118` |
| `custom.el` moved to `user-lisp/`, loaded with `noerror` | First launch no longer fails without `custom.el` | `early-init.el:10` |
| `executable-find` cache now Windows only | No longer runs on macOS | `early-init.el:120-131` |
| `_GUI` and `_TUI` constants removed | TUI has no special path | `nn.el:1-2` |
| `use-package` added: `cape`, `etags`, `winner`, `yasnippet-capf`. Removed: `man`, `nn-word-move` | Own word motion dropped; snippet completion uses a package | `use-package` lists of both commits |
| Line-scaling flags added for underline, overline, strike-through | Display only | `early-init.el:44-46` |

## 4. Feature inventory: A against B

Port effort means the work to make the feature run inside B. Small: copy one file and add one `require`. Medium: copy, then adapt to B's defaults. Large: rework B's own settings or many bindings.

| Feature | A | B (`origin/main`) | Port effort |
|---|---|---|---|
| Anvil MCP (`anvil`, `anvil-emacs-eval`) | `lisp/init-local.el:530-537`, `lisp/init-local-ai.el:25-51`, pin `lisp/package-list.el:11-13`, bridge `~/.emacs.d/anvil-stdio.sh` | None | Medium: install `anvil.el`, start the server, copy or reinstall the bridge, keep the `org` module off (`lisp/init-local-ai.el:22-25`) |
| Emacs server for `emacsclient` | `init.el:207-209` | None. Daemon-aware hooks only (`init.el:96-101`, `nn.el:97-100`) | Small |
| Hel and the SPC leader | `lisp/init-local-hel.el` (493 lines, leader at `:39-235`), pins `lisp/package-list.el:20-29` | None. Viper off by default | Large: the leader targets A's commands, and B's global keys act in Hel insert state |
| org-gtd and the `~/org` pipeline | `lisp/init-local-gtd.el` (pin 4.6.1 at `lisp/package-list.el:49-51`, `org-gtd-directory` at `:194`), `lisp/init-local-org.el:14-25`, `docs/org-gtd-pipeline-spec.md` | No GTD. Own Org setup: 7 TODO keywords, agenda file `~/agenda.org`, 5 capture templates (`user-lisp/init-lang.el:626-845`, `:759`, `:784-795`) | Large: two Org setups set the same variables |
| Org case guard | `lisp/init-local-case-guard.el`, `C-x C-u` unbound at `lisp/init-local.el:512`, Hel case keys unbound at `lisp/init-local-hel.el:234-235` | None | Small: the guard advises `upcase-region` and the word commands (`:264-269`), so it also covers B's `M-u` |
| Denote | `lisp/init-local-denote.el:12-16` (folder `~/Obsidian/Note/`), journal helpers `:61-191` | None | Small |
| Vulpea | `lisp/init-local-vulpea.el:22-27`, Hel key at `lisp/init-local-hel.el:214` | None | Small |
| Append-and-review note | `lisp/init-local-append-review.el` | None | Small |
| Ghostel | `lisp/init-local-shell.el:209-318`, module dir `:215-219` | Yes: `user-lisp/init-tools.el:360-386`, `` C-` `` | Small to medium: merge two setups, then build or download the module again |
| Herdr (`SPC h e`) | `lisp/init-local-hel.el:137`, `lisp/init-local-herdr.el:151-157` | None | Small, after the PATH import |
| mdired | Not part of A. It is a package that was researched on 2026-11-09, but not installed (memory note, not a repo source) | Not found | None |
| claude-code-ide | Removed 2026-10-12 (`CHANGELOG.md:40`, commit `5b181842`) | None | None |
| Frame-state cache | `early-init.el:50-53`, `lib/frame-state.el`, `docs/frame-state-cache.md` | No restore. Frames open maximized (`early-init.el:84-89`) | Small |
| macOS modifier keys | `lisp/init-osx-keys.el:6-7`, then `lisp/init-local-macos.el:6-7` wins (live: option=meta, command=super) | None set. Emacs defaults match A | None |
| PATH import | `lisp/init-exec-path.el:5-15` | Windows only | Small |
| `async-installer` and `external-packages/` | `lisp/init-local-async-installer.el:5-11`, 6 Git pins in `lisp/package-list.el` | `:vc` with `:rev :newest` for 3 own packages | Medium: keep it, or move pins to `:vc :rev` |
| Auto save | `lisp/init-local.el:97-115` (checkout at `~/github/auto-save`) | None | Small |
| Persistent undo | `lisp/init-local.el:80-95` | None. `C-z` undo, `C-S-z` redo (`user-lisp/init-keybind.el:65-66`) | Small |
| Minibuffer completion | vertico, orderless, consult, embark (`lisp/init-minibuffer.el`), `vertico-posframe` (`lisp/init-local.el:263-271`), 5 consult keys in the leader | `fido-vertical-mode` (`user-lisp/init-editor.el:380-381`) | Medium: choose one stack |
| Theme and mode line | modus-themes, doom-modeline (`lisp/init-local-themes.el:6,71`) | own theme and mode line (`init.el:92-94`, `user-lisp/init-display.el:321`) | Small |
| Proofread and LLM proof | `lisp/init-local-ai.el:56-62` (gitignored config) | Stubs only | Medium |
| Windows support | `lisp/init-local-windows.el` | Windows first | None on this Mac |

### B defaults that change behavior on this Mac

| Default | B | A | Source |
|---|---|---|---|
| Trailing whitespace | Deleted on every save, all buffers. This also removes Markdown hard line breaks | `ws-butler` in `prog-mode` only | B `user-lisp/init-display.el:194-197`; A `lisp/init-local.el:117-119` |
| GC | Threshold and percentage at `most-positive-fixnum` for the whole session; `garbage-collect` after each 5 s idle | 128 MB after startup, then gcmh | B `early-init.el:8,74-75`; A `init.el:37-40,65-69`. The Emacs docstring of `gc-cons-percentage` says "never use a too-high value for prolonged periods of time" |
| Native compilation | JIT off. The Emacs 31.1 default is t | Default | B `early-init.el:23-24`; batch print |
| Package signatures | `package-check-signature` nil for every install | Default `allow-unsigned`; nil only in one scoped `let` | B `early-init.el:151`; A `lisp/init-elpa.el:127`; batch print |
| Archives | Tsinghua mirrors of GNU ELPA and MELPA. NonGNU ELPA is absent | GNU, NonGNU, MELPA | B `early-init.el:152-154`; Emacs default `package-archives` (batch print); A `early-init.el:43` |
| `use-package` | `always-ensure t`, `always-defer t` | Explicit `:ensure t` per form | B `early-init.el:159-160`; `use-package-core.el:175-177` ("assume `:defer t' unless `:demand' is used") |
| URLs | Open in EWW | System browser | B `early-init.el:113` |
| Identity and mail | Author's name, mail address, SMTP server, and SMTP user | Not set in the repo | B `early-init.el:71-72`, `user-lisp/init-www.el:118-121` |

## 5. Built-in facts that decide the paths

| Fact | Source |
|---|---|
| `--init-directory DIR` sets `user-emacs-directory` to DIR | `startup.el:1420-1428`; Emacs manual, node Initial Options (`emacs.info` line 46804) |
| If DIR has no `init.el`, Emacs falls back to the usual `init.el`. B has one, so this does not apply | Emacs manual, same node |
| Delayed defaults get their value after argument parsing and before `early-init.el`. So `package-user-dir`, `user-lisp-directory` follow DIR. Batch check: `DIR/elpa`, `DIR/user-lisp/` | `startup.el:1468-1474,1533-1541`; `package.el:280-286`; `startup.el:1202-1223`; `emacs -Q --batch --init-directory` print |
| The `eln-cache` path follows `user-emacs-directory` after `early-init.el` | `startup.el:1544-1545` |
| `prepare-user-lisp` runs after `early-init.el` and package activation. With `user-lisp-auto-scrape` nil it only adds dirs to `load-path` | `startup.el:1566,1570-1572,1243-1284`; B `early-init.el:73` |
| The server socket is `$TMPDIR/emacs<uid>/<server-name>`, shared by all Emacs processes of one user | `server.el:285-293` |
| `server-start` with another live server of the same name shows "Unable to start the Emacs server" and leaves the other server running | `server.el:728-740` |
| The Anvil bridge accepts `--socket=path` | `~/.emacs.d/anvil-stdio.sh:240-241` |

Effect: a trial with `--init-directory` keeps B's packages, state, and native code in B's dir. A's server and Anvil keep running. B shares only the files it opens and the paths it hard-codes: `org-directory` (default `~/org`), `~/agenda.org` (`user-lisp/init-lang.el:759`), `~/Downloads` (`user-lisp/init-www.el:357`), `~/Music` (`user-lisp/local/simple-mpv.el:74`).

## 6. Switch paths

### (a) Full replace

- Steps: make a fork or clone of B outside `~/Projects`, then `cd ~ && ln -sfn <B-dir> .emacs.d`, then restart Emacs.
- Lost at once: everything in section 2. The MCP clients fail because `~/.emacs.d/anvil-stdio.sh` is gone.
- Must edit first: B's identity and mail settings (`early-init.el:71-72`, `user-lisp/init-www.el:118-121`).
- State: B writes `elpa/`, `var/`, `eln-cache/` into its own dir (B `.gitignore` ignores them). `user-lisp/custom.el` is also ignored: the `custom.el` pattern at `.gitignore:6` matches at any depth.
- Rollback: `cd ~ && ln -sfn Projects/emacs.d .emacs.d`, then restart Emacs. A's untracked state (`elpa-31.1/`, `external-packages/`, `anvil-stdio.sh`, `custom.el`) stays in place, so the rollback is complete.

### (b) Fork B, port A's local layer into `user-lisp/`

- Size: the `init-local` files plus `lisp/package-list.el` are 3,968 lines (`wc -l`, without the base file `lisp/init-locales.el`). The layer also uses A's base: `require-package` and `maybe-require-package` (8 uses, from `lisp/init-elpa.el`), `sanityinc/` window helpers (2 uses, `lisp/init-local-hel.el`), and the vertico and consult stack.
- Hook point: B loads modules by an explicit `require` list (`init.el:16-23`). Add one `require` for a new `init-local` file, and keep A's code in new files. This keeps upstream merges small.
- Conflicts to resolve:
  - `use-package-always-defer t` stops 5 A forms whose `:config` turns on a mode or a theme and that have no load trigger: `modus-themes`, `undo-fu-session`, `yasnippet`, `golden-ratio` (`lisp/init-local-themes.el:6`, `lisp/init-local.el:88,178,273`), and `org-modern` (`lisp/init-local-org.el:258`). Add `:demand t` to each.
  - fido against vertico. Both cannot run.
  - B's global keys against Hel insert state.
  - B's Org settings against A's Org and org-gtd settings.
  - B's global `delete-trailing-whitespace` against A's `ws-butler`.
  - B's archives without NonGNU ELPA against A's package list. Not confirmed which A packages come only from NonGNU ELPA.
- Upstream cost: B's commit messages do not say what changed. The last 6 commits moved 4 modules into one file. Each upstream merge needs a full diff review.
- License: the fork is GPL-3.0. A is BSD-2-Clause, inherited from the upstream `purcell/emacs.d` (A `LICENSE`; GitHub API). Not confirmed that BSD-2-Clause code may go into a GPL-3.0 work: the FSF license list (https://www.gnu.org/licenses/license-list.html) timed out from here.
- Rollback: same as (a).

### (c) Keep A, borrow ideas

C1 section 11 ranks ten ideas. Status on `origin/main`:

| C1 rank | Idea | `origin/main` location | Status |
|---|---|---|---|
| 1 | Run-once hooks `nn-first-input`, `nn-first-file` | `nn.el:59-124` | Still the best gain. A already has an idle `require` helper (`lisp/init-local.el:406-412`) |
| 2 | Eglot tuning, flymake restart after diagnostics | `user-lisp/init-editor.el:292-332`, `:172` | Still valid. Lower value: A has `init-eglot` commented out (`init.el:93`) |
| 3 | `executable-find` cache | `early-init.el:120-131` | Drop for macOS. B now caches on Windows only, and A measures about 0.1 ms per call on macOS (`lisp/init-local-windows.el:13`) |
| 4 | File handlers off during load | `early-init.el:52-61`, `init.el:15` | Still valid |
| 5 | apheleia format key | `user-lisp/init-editor.el:189-210` | Still valid |
| 6 | Magit and ediff trimming | `user-lisp/init-tools.el:155-180,191-231` | Still valid |
| 7 | Transient autoload deferral | `user-lisp/init-keybind.el:2-35` | Fragile: it advises the private functions `transient--load-command-if-autoload` and `transient--init-suffix` |
| 8 | `project.el` setup | `user-lisp/init-builtin.el:11-23` | Still valid |
| 9 | Font fallback loops | `init.el:25-82` | Still valid |
| 10 | citre and ctags | `user-lisp/init-editor.el:224-291` | Still optional |

License: B is GPL-3.0 and A is BSD-2-Clause. A verbatim copy brings GPL-3.0 terms into A. Write the idea again in your own code, or accept a mixed license on purpose. Do not copy `color-picker.el`: it has no license.

### (d) Trial with `--init-directory`

- A stays untouched. `~/.emacs.d` keeps pointing at A. A's server and Anvil keep running.
- First launch downloads about 28 archive packages, their dependencies, and 3 Git packages into the trial dir.
- Keep B out of `~/org`: set `org-directory` to a trial folder in B's `custom.el`, which loads before Org (`early-init.el:10`).
- Do not save files under `~/org` or in A's repo from B. B deletes trailing whitespace on each save.
- To test Anvil against B, give B another `server-name` and pass `--socket=<path>` to the bridge. A plain `server-start` in B only warns while A runs.

## 7. Recommended steps

Trial (path d):

```sh
D=~/.local/share/emacs-trial-b
git clone https://github.com/zHaOdANiuu/.emacs.d.git "$D"
git -C "$D" switch --detach 43e8334
mkdir -p "$D/org-trial"
printf '%s\n' ';;; -*- lexical-binding: t -*-' \
  '(setq org-directory (expand-file-name "org-trial/" user-emacs-directory))' \
  > "$D/user-lisp/custom.el"
open -n -a Emacs --args --init-directory "$D"
```

1. Run the commands above. The last line starts a second Emacs.app instance with B.
2. Use B for normal editing outside `~/org` for some days. Write down each A feature that you miss.
3. Check that A still answers Anvil calls during the trial.
4. Decide. If B's base (fido, CUA-like keys, no Hel) does not suit you, take path (c). If it suits you, plan path (b) as a separate task.

Rollback of the trial: quit the B instance, then run `trash ~/.local/share/emacs-trial-b`. Nothing in A changes.

Path (c) after the trial: take one idea per commit. Run `./test-startup.sh` before each commit and `./test-startup-clean.sh` before a push (`AGENTS.md`). Rollback: `git revert <commit>`.

## 8. Knock-on effects outside Emacs

| Item | (a) Full replace | (b) Fork B and port | (c) Keep A | (d) Trial |
|---|---|---|---|---|
| A repo | Stays, but no longer runs | Becomes the old config; the port lives in the fork | Normal small commits | Unchanged |
| CI (`.github/workflows/test.yml`) | Tests a config you do not run | Rewrite. B needs Emacs 31, but the matrix pins 30.1 (`test.yml:17-22`) | Unchanged. Borrowed code must also start on 30.1 | Unchanged |
| 85 ERT tests (`tests/*.el`) | Not run against the live config | Paths change: tests load `../lisp/<module>` (for example `tests/init-local-gtd-tests.el:19`) | Unchanged. Add tests for new logic | Unchanged |
| Startup tests (`test-startup.sh`, `test-startup-clean.sh`) | Test the old config | Rewrite for B's layout. The `C-x C-u` check (`test-startup.sh:24-26`) still applies | Unchanged | Unchanged |
| Docs (Hel, Ghostel, org-gtd, Dired, append-review cheat sheets, `docs/frame-state-cache.md`) | Stale | Move and update | Unchanged | Unchanged |
| Agent files (`AGENTS.md`, `CONTEXT.md`, `.claude/agents/elisp-reviewer.md`, `.claude/agents/test-writer.md`, `.agents/skills/new-init-module`, `.agents/skills/org-case-check`) | Describe a config that does not run | Rewrite for `user-lisp/` and B's names | Unchanged | Unchanged |
| Privacy workflow (`.github/workflows/privacy.yml`) | Not on B | Copy to the fork | Unchanged | Not applicable |
| Agent tooling that uses Anvil (`~/.claude/rules/tooling.md`) | Anvil tools fail. The rule says the Git-read hook blocks only "when Anvil is reachable", so plain Git reads work again, but Anvil file edits do not | Same until Anvil is ported | Unchanged | Unchanged |

## 9. C1 claims that changed

| C1 claim | Now | Source |
|---|---|---|
| B has 11 modules (C1 section 1) | 8 modules | B `init.el:16-23` |
| B's `lexical-binding` nil is risky (C1 sections 1 and 11) | No-op on Emacs 31.1 | B `early-init.el:7`; `etc/NEWS:3805-3810` |
| `nn-directory` is `~/.emacs.d/var/` (C1 section 1) | `user-emacs-directory` + `var/`. The README mismatch remains | B `nn.el:8`; `README.org:19,85` |
| `executable-find` cache for all systems (C1 sections 8 and 11) | Windows only | B `early-init.el:120-131` |
| B has `_TUI` (C1 section 8) | Removed | B `nn.el:1-2` |
| Dape in `init-debug.el`, magit in `init-vc.el`, Ghostel in `init-terminal.el` (C1 sections 5 and 7) | All in `init-tools.el` | B `user-lisp/init-tools.el:191,232,360,391` |
| `<f12>` bound twice (C1 section 9) | Still twice globally: `citre-jump` and `xref-find-definitions`. Emacs Lisp mode adds a third, local binding | B `user-lisp/init-editor.el:227,336`; `user-lisp/init-lang.el:21` |
| `orderless` named but not installed (C1 section 3) | Still true | B `user-lisp/init-editor.el:409` |
| A uses compile-angel (C1 section 8) | No match in A's `init.el`, `early-init.el`, or `lisp/` | `rg compile-angel` |
| A has claude-code-ide (C1 section 2) | Removed 2026-10-12 | A `CHANGELOG.md:40` |
| A's `init-eglot.el` installs eglot (C1 section 5) | `init-eglot` is commented out | A `init.el:93` |
| A's macOS modifier conflict "likely" resolves to `init-local-macos` (C1 section 10) | Confirmed: option=meta, command=super in the live session | live session; A `lisp/init-local-macos.el:6-7` |

## 10. Not confirmed

- That BSD-2-Clause code may go into a GPL-3.0 work: the FSF license list timed out from here.
- B's PATH gap at runtime: I did not run B. The claim comes from the empty `launchctl getenv PATH`, the missing `LSEnvironment` in the app bundle, and B's source.
- Whether `open -n -a Emacs --args ...` passes the shell's PATH to the new instance. `open(1)` documents `--env` to add variables, but does not say which variables it passes by default.
- Which of A's packages come only from NonGNU ELPA, and so fail with B's archives.
- All runtime behavior of B on this Mac. I read B's source only.
