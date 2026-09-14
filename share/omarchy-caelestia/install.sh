#!/usr/bin/env bash
# Install Caelestia shell LOOKS on Omarchy without replacing Hyprland keybinds
# or the packaged quickshell that Omarchy needs.

set -euo pipefail

LOG="${HOME}/.local/share/omarchy-caelestia/install.log"
mkdir -p "${HOME}/.local/share/omarchy-caelestia" \
         "${HOME}/.local/bin" \
         "${HOME}/.config/quickshell" \
         "${HOME}/.config/caelestia" \
         "${HOME}/Pictures/Wallpapers"

exec > >(tee -a "$LOG") 2>&1
echo "===== $(date) caelestia-for-omarchy install ====="

if pacman -Q quickshell-git &>/dev/null; then
  echo "ERROR: quickshell-git is installed. That replaces Omarchy's quickshell."
  exit 1
fi

echo ">>> Extra packages"
sudo pacman -S --needed --noconfirm \
  fish aubio libqalculate cmake ninja swappy pkgconf lm_sensors \
  ttf-cascadia-code-nerd ttf-material-symbols-variable \
  qt6-base qt6-declarative qt6-imageformats qt6-shadertools

echo ">>> AUR packages (NOT caelestia-shell / NOT quickshell-git)"
yay -S --needed --noconfirm --answerclean N --answerdiff N --answeredit N \
  libcava ttf-rubik-vf qt6-m3shapes-git caelestia-cli

if pacman -Q quickshell-git &>/dev/null; then
  echo "ERROR: install pulled quickshell-git. Aborting to protect Omarchy."
  exit 1
fi

echo ">>> Packaged quickshell still: $(pacman -Q quickshell)"

SRC="${HOME}/.config/quickshell/caelestia"
if [[ ! -d $SRC/.git ]]; then
  git clone --depth 1 https://github.com/caelestia-dots/shell.git "$SRC"
fi

echo ">>> Build Caelestia C++ plugin into ~/.local (leave Omarchy qs alone)"
cd "$SRC"
rm -rf build
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DVERSION=2.4.0 \
  -DGIT_REVISION="$(git rev-parse HEAD)" \
  -DDISTRIBUTOR=omarchy-user \
  -DCMAKE_INSTALL_PREFIX="${HOME}/.local" \
  -DINSTALL_LIBDIR=lib/caelestia \
  -DINSTALL_QMLDIR=lib/qt6/qml \
  -DENABLE_MODULES="extras;plugin"
cmake --build build
cmake --install build

BG_SRC="${HOME}/.local/state/omarchy/current/background"
if [[ -e $BG_SRC ]]; then
  cp -L "$BG_SRC" "${HOME}/Pictures/Wallpapers/omarchy-current.jpg" || true
fi

chmod +x "${HOME}/.local/bin/omarchy-caelestia-start" \
         "${HOME}/.local/bin/omarchy-caelestia-stop" \
         "${HOME}/.local/bin/omarchy-caelestia-toggle-bar"

mkdir -p "${HOME}/.local/state/omarchy/toggles"
touch "${HOME}/.local/state/omarchy/toggles/bar-off"
omarchy-shell -q omarchy.bar syncHidden || true

echo ">>> Launch Caelestia"
pkill -f '[q]uickshell.*caelestia' 2>/dev/null || true
"${HOME}/.local/bin/omarchy-caelestia-start" &
sleep 2

if pgrep -f '[q]s .*-c caelestia|[q]uickshell.*caelestia' >/dev/null; then
  echo "SUCCESS: Caelestia shell is running."
  notify-send -u normal "Caelestia shell" "Looks swapped. Super+Space and Super+K are unchanged." || true
else
  echo "WARNING: Caelestia did not stay running. Check journalctl --user -t caelestia-shell"
  journalctl --user -t caelestia-shell -n 80 --no-pager || true
  notify-send -u critical "Caelestia shell" "Install finished but the shell did not stay running. See ~/.local/share/omarchy-caelestia/install.log" || true
  exit 1
fi

echo "===== done $(date) ====="
