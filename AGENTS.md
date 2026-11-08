# Shadow OS Factory — Agent Guide

This repo builds a custom Debian live image with `live-build`. **Use the Debian Live Manual as the authoritative reference** and prefer its documented mechanisms over ad-hoc workarounds.

## Documentation (read first)

- Manual index: https://live-team.pages.debian.net/live-manual/html/live-manual.en.html
- Customizing contents (includes, hooks, preseeding): https://live-team.pages.debian.net/live-manual/html/live-manual/customizing-contents.en.html
- Customizing run-time behaviours (live user, locale/keyboard, persistence): https://live-team.pages.debian.net/live-manual/html/live-manual/customizing-run-time-behaviours.en.html
- Managing a configuration (`auto/config`): https://live-team.pages.debian.net/live-manual/html/live-manual/managing-a-configuration.en.html
- Overview of tools (`live-build`, `live-boot`, `live-config`): https://live-team.pages.debian.net/live-manual/html/live-manual/overview-of-tools.en.html

When unsure, fetch the relevant manual page with `webfetch` (markdown format) and follow the documented approach.

## Key facts (doc-aligned)

- **Live user is created at boot by `live-boot`, not at build time.** Configure via `lb config --bootappend-live "boot=live components ..."` and live-config.
- **`boot=live components`** must be present in live boot parameters for live-config runtime behavior.
- **`config/includes.chroot/`** maps to `/` in the live system and is overlaid **after package installation** (can overwrite package files). In this project, `config/includes.chroot_after_packages/` is used for post-package content.
- **Runtime config values** (e.g. groups) belong in `config/includes.chroot*/etc/live/config.conf.d/*.conf` as shell variable assignments (e.g. `LIVE_USER_DEFAULT_GROUPS="..."`). **Do not put executable commands** (`su`, session tools) in `config.conf.d/*.conf`; those files are sourced during live-config init.
- **Boot-time/live-config hooks**: add prefixed hooks/components under `config/includes.chroot*/lib/live/config/` following the sequence/format used by `/lib/live/config/` components (see manual 9.2.3 and `/usr/share/doc/live-config/`). This is the right place for post-user-setup actions (password handling, home/KDE tweaks) when they must run at boot.
- **Package lists**: `config/package-lists/*.list.chroot` select packages.
- **Preseeding**: `config/preseed/*.cfg.{chroot,binary}` for debconf, not for live-config runtime.

## Project decisions / build notes

- Target: Debian **trixie**, amd64, `iso-hybrid`, bootloaders `grub-efi,grub-pc`.
- `build.sh` is the entry point; it runs `lb config` + `lb build`. Keep **`--apt-recommends true`** (user preference). Keep **`--firmware-chroot false`** to avoid `firmware-b43-installer`/`firmware-b43legacy-installer` postinst network-download failures in non-interactive builds; add needed firmware packages explicitly to package lists instead.
- Use `DEBIAN_FRONTEND=noninteractive` for builds. Container builds may run without a hard root check if the environment is already privileged.
- Clean rebuilds: `./build.sh --purge` removes cache/build state (slow). `cache/`/`chroot/` may contain root-owned files; remove with appropriate privileges if needed.

## Known pitfalls (diagnosed previously)

- **No live user / SDDM shows password prompt, no user selector, no autologin**: often caused by live-config not completing. Check `boot=live components`; valid groups in `user.conf` (avoid non-existent groups like `powerdev`/`scanner` unless present); no commands in `config.conf.d/*.conf`; `0030-user-setup`/DM component state in `/var/lib/live/config/` and logs (`live-config.debug`). Stock `0030-user-setup` (live-config 11.x) does not read `LIVE_PASSWORD` — handle password via a proper live-config hook/component or an intentional alternative.
- **SDDM theme not applied**: `Current=` in `/etc/sddm.conf.d/*.conf` must match an installed theme under `/usr/share/sddm/themes/<name>`. SDDM autologin is configured by the live-config SDDM component; keep theme/autologin compatible (drop-in files in `sddm.conf.d` are safer than fighting component behavior).
- **`dictionaries-common`/`aspell-autobuildhash` trigger crash** (large recommends/desktop stacks): seen as `Undefined subroutine &main::subst` / aspell hash build errors during triggers. Treat as a chroot package-config issue; prefer minimal, targeted workarounds (diversion/hook/fixed script applied before trigger) and keep the fix documented.
- **Core config deleted/regenerated**: `a87d998`/`e5bc94d` removed tracked `config/binary|bootstrap|chroot|common|source`; `lb config` regenerates them. Keep durable build options in `build.sh` (and/or a maintained `auto/config`).

## Plan (future work, documentation-first)

> Work on branch `issue` as requested; keep commits/history. Copy known-good pieces incrementally.

1. **Stabilize base (current)**
   - [ ] Ensure `cache/`/`chroot/` leftovers are removed with proper privileges.
   - [ ] Confirm `build.sh` is the single, durable source of `lb config` options (or add `auto/config` per manual “Managing a configuration”).
   - [ ] Create minimal `config/package-lists/` (live essentials + chosen desktop/SDDM) with `--apt-recommends true` kept in mind.

2. **Live user & login (doc-aligned)**
   - [ ] Add `config/includes.chroot/etc/live/config.conf.d/10-user-setup.conf` (or `user.conf`) with `LIVE_USERNAME`, `LIVE_USER_FULLNAME`, `LIVE_HOSTNAME`, valid `LIVE_USER_DEFAULT_GROUPS` only.
   - [ ] Implement password/autologin the manual-compatible way (live-config hook/component in `lib/live/config/` with correct sequencing; verify SDDM autologin component behavior).
   - [ ] Boot test with `live-config.debug`; verify `getent passwd`, `/var/lib/live/config/`, `/etc/sddm.conf*` autologin, and logs.

3. **SDDM theme & desktop polish**
   - [ ] Install/provide the actual SDDM theme package/files, then set `Current=<theme>` in `config/includes.chroot/etc/sddm.conf.d/theme.conf`.
   - [ ] Apply KDE/Plasma defaults safely (skel + post-login/autostart), never via commands in `config.conf.d/*.conf`.

4. **Bootloader/GRUB (incremental)**
   - [ ] Copy/restore GRUB changes from `main` incrementally (GRUB first), keeping `--bootloader`/boot params consistent.
   - [ ] Validate ISO-hybrid boot (BIOS + UEFI) after each change.

5. **Reliability & reproducibility**
   - [ ] Add/keep targeted workarounds for known chroot trigger failures (e.g. `aspell-autobuildhash`), documented here.
   - [ ] Review `LB_FIRMWARE_BINARY`/explicit firmware packages for hardware support.
   - [ ] Add a short test checklist (build, boot VM/USB, login/autologin, network, display manager theme).

## Agent workflow

- Before changing live-config/boot behavior, consult the manual sections above.
- Prefer minimal, reversible changes; test one subsystem at a time (GRUB, then SDDM, then user, etc.).
- When a build fails, inspect the *tail* of `shadow-build.log` and distinguish: **fetch/mirror errors**, **dpkg/trigger/configure errors**, and **live-boot/live-config runtime errors**.
- Do not “fix” by adding commands to `config.conf.d/*.conf`; use documented includes/hooks/components.
