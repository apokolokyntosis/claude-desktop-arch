# claude-desktop-arch

Personal Arch package of the official Claude Desktop app, built from
Anthropic's own `.deb`. Nothing is fetched from the AUR; the PKGBUILD was
adapted from the AUR `claude-desktop` package once.

## Setup

    ./install.sh                  # claude-desktop-pkg in ~/.local/bin + update timer
    claude-desktop-pkg update     # build and install (asks for sudo)

`./install.sh --uninstall` removes the timer and the link. The package itself
is removed with `sudo pacman -R claude-desktop-anthropic`.

## How updates work

A systemd user timer runs `claude-desktop-pkg check` 2 minutes after login
and every 6 hours. It downloads the apt repo metadata and verifies:

1. the signing key in `keys/` has the fingerprint Anthropic publishes at
   https://code.claude.com/docs/en/setup,
2. the `InRelease` signature, and that `Valid-Until` has not passed,
3. the hash of the `Packages` index against `InRelease`,
4. the `.deb` hash from `Packages`, written into the PKGBUILD, which makepkg
   checks against the download.

If a newer version exists, a notification offers "Update now", which opens a
terminal running `claude-desktop-pkg update`. A failed verification shows a
critical notification instead. Network errors stay silent and are retried on
the next run.

Every update commits the new version and hash to this repo, so `git log`
is the update history. Downloads and builds live in
`~/.cache/claude-desktop-arch`; old versions are deleted.

Logs: `journalctl --user -u claude-desktop-check`.
Set `$TERMINAL` to choose the terminal (default: first of ghostty, kitty,
alacritty, konsole).

## If Anthropic rotates the signing key

Checks will fail with a critical notification. Get the new fingerprint from
the docs page above (not from the repo), then update `KEY_FPR` in
`bin/claude-desktop-pkg` and replace `keys/anthropic-claude-desktop.asc`.
