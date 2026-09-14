# Backlog

## Hyprland Lua migration — remaining machines

The Lua config (`.config/hypr/hyprland.lua`) is live on junji-pc and passes
`Hyprland --verify-config` on the office box's 0.55.4. Still to do:

- **junji-t14**: `krypt update`, then
  `krypt setup --yes --prompts hypr_apps,hypr_input` — `krypt link` seeds
  `apps.lua`/`input.lua` with their `{{placeholders}}` unfilled. Hand-write
  `monitors.lua`/`workspaces.lua` if the laptop needs them; leave `nvidia.lua`
  commented (no NVIDIA). Log out and back in: `hyprctl reload` does not switch
  from `hyprland.conf` to `hyprland.lua`, only a fresh start does.
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

- **Menu stacking**: audio, bluetooth and top menus open a new instance per
  click. `.menu-wifi` solves this with a flock lock plus debounce; a
  focus-or-launch wrapper would cover the others.
- **GPG key DDC87D28** is not on GitHub, so signed commits show Unverified.
