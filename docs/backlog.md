# Backlog

## Hyprland Lua migration — per-machine leftovers

The Lua config (`.config/hypr/hyprland.lua`) is live on junji-pc, the office box
and junji-t14. What each machine still carries from the migration:

- **junji-t14**: reinstalled 2026-09-13 (new tailnet node `100.64.0.11`, new SSH
  host keys), migrated 2026-09-15 like junji-pc: `krypt update`,
  `krypt setup --yes --prompts hypr_apps,hypr_input`, template monitor rule, tpm
  and plugins on junji-pc's commits, fork pikr `aa25687` built in
  `~/.cache/pikr-fork` (the `local` branch is not on GitHub; it was sent as a
  git bundle). Pre-migration state is in
  `~/backups/t14-pre-lua-2026-09-15.tar.gz`; the legacy `~/.config/hypr/*.conf`
  files remain as a rollback. The stale caveman skills and `RTK.md` files were
  deleted and pruned from its krypt manifest (backup
  `manifest.json.bak-2026-09-15-pre-prune`).
- **Office box** (harryfocker, user julius): migrated 2026-09-14 like junji-pc.
  Its pre-migration state is in `~/backups/files-pre-krypt-2026-09-14.tar.gz`,
  and `~/.cache/pikr-fork` (1.4 GB with build output) holds the checkout the
  fork pikr was installed from.
- **Legacy `.conf` leftovers on junji-pc**: `hyprland.conf`, `apps.conf`,
  `input.conf`, `monitors.conf`, `nvidia.conf`, `workspaces.conf` in
  `~/.config/hypr` are kept as a rollback (Hyprland falls back to them if
  `hyprland.lua` is moved away). Delete by name once the Lua session has run a
  while; also drop the stale `hyprland.conf` and `chromium-flags.conf` link
  entries from `~/.local/state/krypt/manifest.json` (the latter is a template
  now).

## pikr fork (junjitree/pikr)

- `--kb-custom`, the confirm card and `--loading` live on `feat/kb-custom`; the
  empty-password fix on `fix/password-empty-state`. Both merged into the `local`
  branch, installed to `~/.cargo/bin/pikr` (shadows AUR `pikr-bin`;
  `cargo uninstall pikr` reverts). `.menu-wifi` feature-detects both flags from
  `pikr --help`, so it degrades on stock pikr.
- **Open PRs**: kryptic-sh/pikr#45 (`--kb-custom`, `--loading`) and #46
  (password empty-state), and mxaddict/dotfiles#10 (`.menu-wifi`, from the
  `feat/menu-wifi` branch off `mxaddict/main`). #45's first commit message
  claims its e2e tests ran; they didn't (no sway here), which the PR says.
- e2e tests skip locally: they need `sway` (headless) and `wtype`, and sway is
  not installed.

## `.menu-wifi` — open after the 3-round review (2026-09-14)

The review loop hit its round budget with the last round still finding real
issues, so it is INCOMPLETE; the findings below were verified but not fixed.
Evidence is from NetworkManager 1.58.1 sources, pikr's source and a stub harness
(fake `nmcli`/`pikr`/`busctl` on `PATH`); nothing was run against a live access
point.

- **Password on nmcli's argv** (`connection add … wifi-sec.psk`,
  `connection modify … wifi-sec.psk`): readable from `/proc/PID/cmdline` by
  other local users while nmcli runs (`/proc` has no `hidepid`). The supported
  alternative is `nmcli connection up uuid U passwd-file F` with
  `802-11-wireless-security.psk:PW` in a 0600 file; NM source says it saves
  agent-supplied system-owned secrets, but that the password persists is
  unverified without a real connection attempt.
- **pikr trims typed text**, so passwords with leading or trailing spaces can't
  be entered (`Payload::Stdout(query_text.trim())` in `ui/view.rs`). Fix belongs
  in the pikr fork: don't trim in `-P` mode.
- **OWE-TM joins as open**, not with `key-mgmt owe`, which NM also accepts for
  transition-mode access points; whether the supplicant completes the transition
  is unverified.
- **Saved profiles that aren't PSK/SAE** (e.g. an old open profile for a network
  now secured) report the failure every time; the old script deleted and
  re-prompted. Forgetting with Right fixes it by hand.
- **`psk-flags` 1 or 2 profiles**: `connection modify wifi-sec.psk` likely won't
  persist, so the re-prompt fails the same way. Unverified; junji-pc's profiles
  have `psk-flags` 0, the T14 was not checked.
- **Stale list when a rescan is refused or rate-limited**: `wait_for_scan` caps
  the wait, but when NM 1.58 refuses or silently drops a request was not
  measured.
- **No "Connecting…" feedback** while `connection up` runs (up to nmcli's
  timeout); clicks during it are silently ignored by the lock.
- **Picking a network that is still activating** counts as "already on it"
  (`GENERAL.CON-UUID` is set during activation) and does nothing.
- **Double-click to close** reopens the menu: the first click closes the picker,
  the second starts a new run. Pre-existing.
- **"secrets" in a profile name or SSID** can misclassify an unrelated
  activation error as a password failure. Rare.
- **Access points whose AKM NM 1.58.1 doesn't map** (`sae-ext-key`, some FT/FILS
  suites) show as open or WEP in `dev wifi list`; joining fails with NM's error.
  Upstream NetworkManager issue.
- **Broken pikr** (missing, no Wayland display, crash) and an unwritable runtime
  dir fail silently, indistinguishable from a cancel.
- **Stock pikr has no way to forget** a network: the forget key needs the fork's
  `--kb-custom`, and the Disconnect/Forget submenu was removed.
- **Not reviewed**: the pikr fork's own changes, and the behaviour on the T14
  (wifi only, slower scan) beyond timing figures from earlier sessions.

## krypt quirks

- `krypt deps` exits 0 without installing anything; install packages by hand.
- `krypt link` never overwrites a conflicting file; never use `--force` or
  `adopt-edits` here — both would clobber machine-local files or commit
  `gh/hosts.yml` tokens into this public repo.
- Hooks run only on `krypt update`, not `krypt link`.
- `.root/` is not deployed. Its mkinitcpio files are from the old encrypted t14
  install and should not be applied to the current unencrypted one.

## Open questions

- **Waybar workspace clicks do nothing under the Lua config.** Waybar 0.15.0
  sends `dispatch workspace N`, which Hyprland 0.56's Lua config manager rejects
  (`hyprctl dispatch 'hl.dsp.focus({ workspace = "N" })'` works). Waybar master
  has the fix (`bfd0cfe`, "detect dispatch protocol via configProvider",
  July 2026) but it isn't in a release. Decided 2026-09-14 to wait for 0.16.0
  rather than run `waybar-git`; keybinds are unaffected. Affects junji-pc and
  the office box.
- **Menu stacking**: audio, bluetooth and top menus open a new instance per
  click. `.menu-wifi` solves this with a flock lock plus debounce; a
  focus-or-launch wrapper would cover the others.
- **GPG key DDC87D28** is not on GitHub, so signed commits show Unverified.

## README keybinding cheatsheet drifts from `hyprland.lua`

`krypt menu keys` (`SUPER + /`, `.local/bin/.menu-keys`) reads the key combos
from `hyprctl binds` and `tmux.conf` each time it opens, so a changed or added
bind shows up there without editing a list (a new plugin bind still needs a
`plugin-notes.sh` entry for its description). The hand-written "Keybinding
cheatsheet (Hyprland)" tables in `README.md` are a hand-kept copy that can
drift, and already have (checked against `hyprland.lua` on 2026-09-15):

- `$mod + shift + n` is listed as swaync "dismiss". It runs `swaync-client -d`,
  which is `--toggle-dnd`.
- Missing: `$mod + alt + n` (`-C`, close all notifications), `$mod + shift + g`
  (`krypt system start`), `$mod + shift + tab` (cycle back), `XF86PowerOff`
  (power menu).
- `$mod + r` says "qalculate picker"; `krypt menu calc` is pikr's calc mode.

Decision needed: fix the tables, or cut them down to a pointer at `$mod + /`.
The README is also the upstream mxaddict/dotfiles README, and a table is still
readable to someone who hasn't installed anything yet.

## `.menu-bluetooth` (pikr Bluetooth picker)

`krypt menu bluetooth` runs `.local/bin/.menu-bluetooth`: reads go through one
`busctl` `GetManagedObjects` snapshot shaped by `jq`, connect / disconnect /
forget / power are `busctl` calls verified by re-reading the property, and only
scanning and pairing use `bluetoothctl`. Verified against a stub harness (fake
`busctl`, `bluetoothctl`, `pikr` on `PATH`, canned D-Bus JSON), with each guard
broken once to see its test fail. Pairing, bonding and forgetting were also run
against real hardware (AirPods Pro 2 on junji-pc) and checked in an HCI trace;
everything else below was not run against real hardware unless it says so.

### Not covered

- **Passkey and PIN pairing.** The picker pairs under bluetoothctl's
  `KeyboardDisplay` agent, so bluez can negotiate a passkey or a numeric
  comparison — but the script only ever writes `default-agent` and `pair` to
  that session and never answers a prompt, so a device that asks for one times
  out and is handed to bluetui with a notification. Doing it inline means
  reading the session's prompts back and rendering them in a picker.
- **Audio does not follow a fresh pairing.** Reported on junji-pc: connecting an
  already-paired device moves the default sink, pairing a new one does not.
  `module-switch-on-connect` is loaded
  (`.config/pipewire/pipewire-pulse.conf.d/switch-on-connect.conf`) and
  WirePlumber's `default-nodes` already names the device, so routing is
  configured. Reading the module's source for the installed version,
  `manager_added` looks the sink's card up in the manager and `return`s silently
  when it is not there yet — before the `considering switching to` log line —
  which would fire exactly when a card and its sink node appear together, as
  they do on a first pairing. That is a candidate, not a finding: it was never
  reproduced under instrumentation. To settle it, run pipewire-pulse with
  `PIPEWIRE_DEBUG=mod.switch-on-connect#5` and pair a device: no
  `considering switching to` line at all means the card lookup; a line followed
  by `not switching to …` names a different check. Nothing in this script is
  implicated either way — it is a pipewire question.
- **A mouse cannot scan, forget or power off when pikr has `--kb-custom`.**
  Those three are bound to keys (`^S`, `^O`, `Right`) and named in the prompt,
  and `build_list` adds the row through to the actions list only when the keys
  are absent. pikr makes nothing but a row clickable — its sole `Click` handler
  is on the row stack in `ui/view.rs` — so a mouse route means an action row in
  the device list, or a second waybar binding. Both were considered and
  declined: the device lists are meant to hold devices and nothing else, and the
  bar icon is meant to have one click. So with a fork pikr a mouse connects and
  disconnects, and bluetui stays the fallback for the rest. This is a known
  departure from "mouse + keyboard, both work, always"; reopening it means
  giving up one of those two, or a pikr that can make something other than a row
  clickable.
- **Just Works has no MITM protection.** That is the protocol, not the script,
  but it is what inline pairing amounts to.
- **A second adapter.** The first `org.bluez.Adapter1` object (sorted by path)
  is used; devices on another adapter are not listed.
- **Nameless devices** are left out of the scan list (random-address LE beacons
  mostly), so a device that advertises no name can't be paired from the picker.
- **Block / unblock, untrust, rename, per-profile connect.** bluetui does the
  first three; a blocked device is shown as such and refused.

### Not verified

- `bluetoothctl`'s exit status when the daemon returns a D-Bus error. The script
  does not depend on it: success is the `Paired` / `Connected` property.
- When `pair` returns relative to the trust and connect bluetoothctl does after
  pairing. The script sets `Trusted` itself, polls `Connected`, and calls
  `Connect` only if the device is still not connected.
- That discovery ends when the scanning `bluetoothctl` is killed. It is why a
  `busctl` `StartDiscovery` was not used; the BlueZ docs say sessions are per
  client but not that a client's exit releases them.
- `AuthenticationFailed` is broader than "needs a passkey"; handing those to
  bluetui is still the useful response.
- The pikr flags it uses when present (`--kb-custom`, `--loading`) are not in a
  pikr release yet; the stock-pikr paths were exercised in the harness only.

### Shared code with `.menu-wifi`

`notify`, `uptime_ms`, the debounce / toggle / `flock` block and the
rows-file-to-line-number pick mapping are the same logic in both scripts,
written with the same names so they can move. Extract them to a sourced
`.local/bin/.menu-lib` and convert both scripts in one pure-move change. The lib
needs its own `[[link]]`; CI's shellcheck glob only lints executables, so either
make it executable or prove it is reached through `shellcheck -x`.

## Decisions needed

## Keybinding cheatsheet (`krypt menu keys`) — open after the 4-round review (2026-09-15)

What it is: `SUPER + /` runs `.local/bin/.menu-keys`, which lists the Hyprland
binds (`hyprctl binds`, descriptions from `description` in `hyprland.lua`) and
the tmux binds `tmux.conf` and its plugins add (a throwaway tmux server loads
`tmux.conf`; plugin descriptions come from `.config/tmux/plugin-notes.sh`).

### Considered and declined (user's call, 2026-09-15)

All three were raised after the review and declined; kept here so they aren't
re-proposed.

- **Other shortcut layers are not in it.** The round-4 sweep found these
  user-configured sources, ranked by how likely they are to be forgotten:
  1. kanata (`/etc/kanata.kbd`): home-row holds (A/; CTRL, S/L ALT, D/K SHIFT,
     F/J SUPER), hold T symbols, hold G numbers, hold V
     arrows/Home/End/PgUp/PgDn, Caps→Esc, bottom-row Alt/Super swap. kanata has
     no command that lists binds, so it means parsing
     `defalias`/`defsrc`/`deflayer`.
  2. fish: fzf.fish binds set in `config.fish` (Ctrl+F/G/S/P/V) and fzf's
     (Ctrl+R/T, Alt+C). Readable live with `fish -ic 'bind --user'`.
  3. alacritty `[[keyboard.bindings]]` (Shift+Return sends Alt+Return).
  4. waybar `on-click`/`on-scroll` actions; opencode leader (`ctrl+o`); tmux
     mouse (`set -g mouse on`); fish command aliases (notably `gg`/`gl`, which
     `git add .`, commit and push); MangoHud toggles (only where installed).
- **Power key powers off junji-pc.** Live `HandlePowerKey` is `poweroff`
  (`busctl get-property org.freedesktop.login1 ... HandlePowerKey`); the repo's
  `.root/etc/systemd/logind.conf` (`HandlePowerKey=ignore`) is not deployed to
  `/etc`. Hyprland also binds `XF86PowerOff` to the power menu, so a press
  likely opens the menu and shuts down. Not pressed to confirm. Deploying the
  `/etc` file would fix it.
- **Modifier names vs physical keys.** With kanata on, the bottom-row key in the
  Windows position sends Alt and the Alt position sends Super (`defsrc`
  `lctl lmet lalt` vs `base` `lctl lalt lmet`). README "`$mod` = Super (Windows
  key)" and every `SUPER + …` row read wrong physically until kanata is part of
  the cheatsheet or the README says so.

### Behaviour that surprised us (not bugs in the cheatsheet)

- Hyprland `CTRL + arrows` (window resize) takes Ctrl+arrow word-jump from every
  app, including fish vi insert and browser text fields.
- fzf.fish's Ctrl+V/Ctrl+S replace fish's clipboard paste and pager search.
- tmux root binds hide fish binds in non-vim panes: Alt+h (man page), Alt+l,
  Ctrl+h/j/k/l, Ctrl+\\.
- `SUPER + F` can't use left home-row Super (F is that hold key); use J.
- tmux 3.7c: `list-keys -T table key` prints nothing and exits 0; a config with
  a syntax error is skipped silently under `-f` but reported by `source-file`;
  `bind -N note -T table key` with no command keeps the command; a bare `;` key
  must be passed as `\;`; a server stuck in a `run` ignores `kill-server` and
  SIGTERM.
- tmux-sensible binds `R`, `C-n`, `C-p` and the prefix letter only when free, so
  `plugin-notes.sh` marks those entries `optional=1`.

### Deferred (LOW, not triggered by the current config)

- `.menu-keys`: tmux `prefix2` and `-r` (repeat) are not shown; key names like
  `BTab`, `NPage`, `DC`, mouse keys are raw; Hyprland `release`/`longPress`/
  `locked`/`catch_all` and keycode-only binds are not marked (a keycode bind
  would render with an empty key); a tab in a tmux note splits its row; a
  `[`/`*`/`?` in the `tmux.conf` path is globbed by `source-file`; the hung
  `run` job's own child process is left running after the timeout kill.
- `.menu-keys` failures that only reach stderr (nothing visible from the bind):
  `XDG_RUNTIME_DIR` unset, `flock` missing or the lock file unwritable.
- `pkill pikr` in `.menu-keys` closes any open pikr (launcher, autofill), same
  as the other `.menu-*` scripts — declined, kept consistent with siblings.
- vim-tmux-navigator with `@tmux_navigator_disable_when_zoomed 1` breaks its own
  copy-mode-vi C-k/C-l/C-\\ binds (unquoted `$tmux_cmd`); `plugin-notes.sh` then
  reports them missing. Upstream plugin bug.
- Pre-existing, outside this change: `tmux.conf` comments "Start windows and
  panes at 1, not 0" (sets 0) and "Shift Alt vim keys" (no Shift); `tmux.conf`'s
  own copy-mode-vi `y` is overridden by tmux-yank; `.krypt/commands.toml`
  `autofill` description doesn't mention the four modes or that each submits.

### Not verified

- Verified on junji-t14 after its migration (Lua config, 87 described binds,
  same rows as junji-pc, via a stub pikr); not run on the office box or macOS.
- A physical `SUPER + /` press and the toggle-close press were not tested; the
  script was run from a shell, including one real pikr launch.
- Whether Hyprland's `mouse = true` drag binds and `SUPER + F` fullscreen
  toggles behave as their descriptions say (pre-existing binds).
