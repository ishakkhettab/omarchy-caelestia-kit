#!/usr/bin/bash
# Overlay this kit onto an Omarchy user account. Does not touch /usr/share/omarchy.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
HOME="${HOME:-/home/$USER}"

copy() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -d "$src" ]]; then
    mkdir -p "$dest"
    cp -a "$src"/. "$dest"/
  else
    cp -a "$src" "$dest"
  fi
}

echo "Installing Omarchy+Caelestia overlay into $HOME"

copy "$ROOT/bin" "$HOME/.local/bin"
chmod +x "$HOME/.local/bin"/omarchy-* "$HOME/.local/bin"/voxtype-cleanup* "$HOME/.local/bin"/caelestia-omarchy-shim 2>/dev/null || true

copy "$ROOT/config/hypr/looknfeel.lua" "$HOME/.config/hypr/looknfeel.lua"
copy "$ROOT/config/hypr/bindings.lua" "$HOME/.config/hypr/bindings.lua"
copy "$ROOT/config/hypr/autostart.lua" "$HOME/.config/hypr/autostart.lua"
copy "$ROOT/config/omarchy-haptics" "$HOME/.config/omarchy-haptics"
copy "$ROOT/config/omarchy-workspaces" "$HOME/.config/omarchy-workspaces"
copy "$ROOT/config/voxtype/osd" "$HOME/.config/voxtype/osd"
copy "$ROOT/config/caelestia" "$HOME/.config/caelestia"
copy "$ROOT/config/systemd/user/voxtype.service.d" "$HOME/.config/systemd/user/voxtype.service.d"
copy "$ROOT/desktop/omarchy-sounds.desktop" "$HOME/.local/share/applications/omarchy-sounds.desktop"
copy "$ROOT/share/omarchy-sounds" "$HOME/.local/share/omarchy-sounds"
copy "$ROOT/share/omarchy-haptics/library" "$HOME/.local/share/omarchy-haptics/library"

# Rewrite cleanup daemon shebang to this machine's venv if present.
CLEAN="$HOME/.local/bin/voxtype-cleanupd"
VENV_PY="$HOME/.local/share/voxtype-cleanup/venv/bin/python"
if [[ -f "$CLEAN" && -x "$VENV_PY" ]]; then
  sed -i "1s|^#!.*|#!$VENV_PY|" "$CLEAN"
fi

if command -v update-desktop-database >/dev/null; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

if command -v systemctl >/dev/null; then
  systemctl --user daemon-reload || true
fi

echo
echo "Copied overlay. Still on this machine:"
echo "  1. uv tool install caelestia-cli   (if caelestia missing)"
echo "  2. Download Parakeet with voxtype-onnx-avx2 (see AGENT.md)"
echo "  3. Optional: llama-cpp-python + mumble-cleanup GGUF (see AGENT.md)"
echo "  4. omarchy-voxtype-orb set jarvis"
echo "  5. hyprctl reload && hyprctl configerrors"
echo "  6. Log out/in so autostart processes run"
echo
echo "Read AGENT.md before improvising."
