#!/usr/bin/env bash
# Links claude-desktop-pkg into ~/.local/bin and enables the update-check
# timer. Run with --uninstall to undo. Does not touch the pacman package.
set -euo pipefail

REPO_DIR=$(dirname "$(readlink -f "$0")")
BIN_DIR=$HOME/.local/bin
UNIT_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user

if [[ ${1:-} == --uninstall ]]; then
  systemctl --user disable --now claude-desktop-check.timer 2>/dev/null || true
  rm -f "$UNIT_DIR"/claude-desktop-check.{service,timer} "$BIN_DIR/claude-desktop-pkg"
  systemctl --user daemon-reload
  exit 0
fi

mkdir -p "$BIN_DIR" "$UNIT_DIR"
ln -sfn "$REPO_DIR/bin/claude-desktop-pkg" "$BIN_DIR/claude-desktop-pkg"
# Units are copied with the repo path filled in, so moving the repo needs a
# rerun of this script.
for unit in claude-desktop-check.service claude-desktop-check.timer; do
  sed "s|@REPO_DIR@|$REPO_DIR|g" "$REPO_DIR/systemd/$unit" >"$UNIT_DIR/$unit"
done
systemctl --user daemon-reload
systemctl --user enable --now claude-desktop-check.timer
systemctl --user list-timers claude-desktop-check.timer
