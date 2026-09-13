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
- **Office box** (harryfocker, user julius): still on the pre-krypt layout,
  unmigrated.
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
- **PRs to kryptic-sh/pikr wait for Junji's go-ahead** after his own testing.
- e2e tests skip locally: they need `sway` (headless) and `wtype`, and sway is
  not installed.

## krypt quirks

- `krypt deps` exits 0 without installing anything; install packages by hand.
- `krypt link` never overwrites a conflicting file; never use `--force` or
  `adopt-edits` here — both would clobber machine-local files or commit
  `gh/hosts.yml` tokens into this public repo.
- Hooks run only on `krypt update`, not `krypt link`.
- `.root/` is not deployed. Its mkinitcpio files are from the old encrypted t14
  install and should not be applied to the current unencrypted one.

## Open questions

- **RTK**: upstream's AGENTS/Claude RTK wiring was dropped in the merge, but the
  `cargo-install-rtk` hook in `.krypt.toml` and
  `.config/opencode/plugins/rtk.ts` predate it and remain, so `krypt update`
  still installs `rtk`. Keep or remove.
- **Menu stacking**: audio, bluetooth and top menus open a new instance per
  click. `.menu-wifi` solves this with a flock lock plus debounce; a
  focus-or-launch wrapper would cover the others.
- **GPG key DDC87D28** is not on GitHub, so signed commits show Unverified.
