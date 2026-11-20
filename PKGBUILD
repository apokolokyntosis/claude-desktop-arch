# Derived from the AUR claude-desktop PKGBUILD by Kevin Diaz.
#
# This PKGBUILD repackages Anthropic's official Debian package for Arch.
# Only the .deb's file payload (data.tar.xz) is used: its embedded install
# scripts do Debian/Ubuntu-specific work (apt repository registration and
# an AppArmor exception for Ubuntu's user namespace restriction), so none
# of that is reproduced here.
#
# pkgver and sha256sums are written by `bin/claude-desktop-pkg`, which takes
# them from Anthropic's GPG-signed apt metadata. Do not edit them by hand.
#
# The package name differs from the AUR's "claude-desktop" so AUR helpers
# never replace this build with the AUR one during a system upgrade.

pkgname=claude-desktop-anthropic
pkgver=5.11492.5
pkgrel=1
pkgdesc="Official Claude AI desktop app from Anthropic — Chat, Cowork, and Claude Code"
# Only x86_64: the updater verifies and pins the amd64 .deb alone.
arch=('x86_64')
url="https://claude.com/download"
license=('LicenseRef-Proprietary')

# Runtime dependencies, from two sources:
#  - the .deb's "Depends:" field, translated to Arch names (Debian and
#    Arch name the same libraries differently, e.g. libgtk-3-0 -> gtk3);
#  - libraries namcap verified the shipped binaries link directly
#    (cairo, dbus, libx11, ... — otherwise they would only be reachable
#    transitively through gtk3's own dependencies, which is fragile).
# alsa-lib is only a "Recommends:" on Debian, but Chromium needs it for
# audio output, so it is a hard dependency here.
# namcap flags some of these as "may not be needed": those are loaded
# with dlopen(), spawned as programs, or used via D-Bus, all invisible
# to namcap's ELF-header analysis. They are needed.
# qemu-system-x86 and edk2-ovmf run the Cowork sandbox VM. Upstream ships
# them under "Recommends:", which apt installs by default.
depends=('alsa-lib'
         'at-spi2-core'
         'bubblewrap'
         'cairo'
         'dbus'
         'edk2-ovmf'
         'expat'
         'gcc-libs'
         'glib2'
         'glibc'
         'gtk3'
         'hicolor-icon-theme'
         'libcap-ng'
         'libcups'
         'libdrm'
         'libnotify'
         'libpipewire'
         'libseccomp'
         'libsecret'
         'libx11'
         'libxcb'
         'libxcomposite'
         'libxdamage'
         'libxext'
         'libxfixes'
         'libxkbcommon'
         'libxrandr'
         'libxtst'
         'mesa'
         'nspr'
         'nss'
         'pango'
         'qemu-system-x86'
         'socat'
         'systemd-libs'
         'util-linux-libs'
         'virtiofsd'
         'xdg-desktop-portal'
         'xdg-utils')

optdepends=('gnome-keyring: credential storage via Secret Service (GNOME)'
            'kwallet: credential storage (KDE Plasma)'
            'libayatana-appindicator: system tray icon'
            'openssh: system SSH client for remote sessions'
            'xdg-desktop-portal-gtk: portal backend for GTK desktops'
            'xdg-desktop-portal-kde: portal backend for KDE Plasma')

provides=('claude-desktop')
conflicts=('claude-desktop' 'claude' 'claude-desktop-bin')

# Prebuilt Electron/Chromium binaries: stripping can corrupt them
# (embedded resources, V8 snapshot data) and saves nothing. !debug skips
# the -debug package, which only makes sense when compiling from source.
options=('!strip' '!debug')

_baseurl="https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop"
source=("claude-desktop.sh"
        "${_baseurl}/claude-desktop_${pkgver}_amd64.deb")
sha256sums=('2b50c019e70b263750255c446bab8db6ab1e50c7396d37ef6547cf118131da65'
            'b96208b207e450b740f7dbe304f6077fed80e7f3d37ddd545991c4e8201564cf')

package() {
  # makepkg unpacks the .deb (an ar archive) into $srcdir: debian-binary,
  # control.tar.xz (metadata and maintainer scripts, unused) and
  # data.tar.xz, the file payload, which is the entire package.
  tar -xf data.tar.xz -C "$pkgdir"

  # Upstream's /usr/bin/claude-desktop is a bare symlink to the Electron
  # binary, which leaves Electron on X11 (XWayland under Wayland, blurry on
  # scaled displays). The launcher selects Wayland when appropriate and
  # honours ~/.config/claude-desktop-flags.conf.
  rm -f "$pkgdir/usr/bin/claude-desktop"
  install -Dm755 claude-desktop.sh "$pkgdir/usr/bin/claude-desktop"

  # Chromium's setuid sandbox helper. Arch enables unprivileged user
  # namespaces, so it is only a fallback (e.g. linux-hardened), shipped the
  # way upstream and every Chromium-based package does.
  chmod 4755 "$pkgdir/usr/lib/claude-desktop/chrome-sandbox"

  # Debian's package linter overrides, no consumer on Arch.
  rm -r "$pkgdir/usr/share/lintian"

  # Upstream's postinst copies these MIME types (.mcpb, .dxt, .skill) into
  # place at install time. Shipping the file lets shared-mime-info's pacman
  # hook register them. The GNOME search provider that postinst also sets
  # up is left out: it needs GNOME Shell and gjs.
  install -Dm644 "$pkgdir/usr/lib/claude-desktop/resources/linux-mime/com.anthropic.Claude.xml" \
    "$pkgdir/usr/share/mime/packages/com.anthropic.Claude.xml"

  # --- Cowork compatibility shims -------------------------------------
  # The app hardcodes Debian's paths for the Cowork VM stack; these
  # symlinks map them to where Arch installs the pieces.
  #
  # virtiofsd: Debian ships it in /usr/bin, Arch in /usr/lib.
  ln -s ../lib/virtiofsd "$pkgdir/usr/bin/virtiofsd"

  # The app opens /usr/share/OVMF/OVMF_CODE_4M.fd (Debian naming). On Arch,
  # /usr/share/OVMF is a compat symlink to /usr/share/edk2 (owned by
  # edk2-ovmf), so links with the Debian names go into /usr/share/edk2.
  install -d "$pkgdir/usr/share/edk2"
  ln -s x64/OVMF_CODE.4m.fd "$pkgdir/usr/share/edk2/OVMF_CODE_4M.fd"
  ln -s x64/OVMF_VARS.4m.fd "$pkgdir/usr/share/edk2/OVMF_VARS_4M.fd"

  # Cowork also needs the vhost_vsock kernel module. It declares a devname
  # alias, so the kernel loads it on first open of /dev/vhost-vsock.

  install -Dm644 "$pkgdir/usr/share/doc/claude-desktop/copyright" \
    "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
