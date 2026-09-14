# AGENT.md — replicate this Omarchy desktop

Instructions for another coding agent on a **second Omarchy PC**. Follow in order.
Do not invent extra theming. Do not edit `/usr/share/omarchy/`.

## Preconditions

- Omarchy Linux, Hyprland, user session
- Network
- `python3`, `pipewire` (`pw-play`), `git`, `curl`
- Voxtype installed (`pacman -Q voxtype` or the distro package)

## Hard rules

1. User config only: `~/.config/`, `~/.local/bin/`, `~/.local/share/`, `~/.config/systemd/user/`.
2. Keep Omarchy default bindings. Super+Space (launcher) and Super+K (keybind guide) must still work.
3. Caelestia is **looks only**. Do not replace Omarchy menus/lock.
4. Do not commit or copy ASR model weights. Download them on the target.
5. Dictation orb that should ship as default: **jarvis** (`voxuirestyle`). `dictator` does not render well yet — leave it in tree but do not enable.

## Install

```bash
cd ~/Projects/omarchy-caelestia-kit   # or clone this repo
chmod +x install.sh
./install.sh
```

`install.sh` copies overlay files, links Kenney sounds, writes the Voxtype systemd
drop-in, and prints leftover model-download commands.

## After install (agent must do)

1. Install Caelestia if missing:
   ```bash
   uv tool install caelestia-cli
   # shell binary should be `qs` (quickshell) — already on Omarchy
   ```
2. Pin Voxtype daemon to the ONNX CPU binary (Intel/AMD without NVIDIA):
   - File: `~/.config/systemd/user/voxtype.service.d/gpu.conf`
   - `ExecStart=/usr/lib/voxtype/voxtype-onnx-avx2 daemon`
   - Then: `systemctl --user daemon-reload && systemctl --user restart voxtype`
   - Use `voxtype-onnx-avx512` only if `lscpu` shows avx512.
3. Download Parakeet (not Whisper) with the **onnx** binary:
   ```bash
   /usr/lib/voxtype/voxtype-onnx-avx2 setup --download --model parakeet-tdt-0.6b-v3-int8 --no-post-install
   /usr/lib/voxtype/voxtype-onnx-avx2 config set engine parakeet
   /usr/lib/voxtype/voxtype-onnx-avx2 config set parakeet.model parakeet-tdt-0.6b-v3-int8
   /usr/lib/voxtype/voxtype-onnx-avx2 config set parakeet.model_type tdt
   ```
   The CLI `voxtype` on PATH may be the Vulkan Whisper build. It **cannot** set `engine parakeet`. Always use `voxtype-onnx-avx2 config`.
4. Cleanup model (optional but this kit uses it):
   ```bash
   uv venv ~/.local/share/voxtype-cleanup/venv
   uv pip install --python ~/.local/share/voxtype-cleanup/venv/bin/python llama-cpp-python
   python3 - <<'PY'
   from huggingface_hub import hf_hub_download
   hf_hub_download(
       repo_id="amitashwini/mumble-cleanup-2stage",
       filename="mumble-cleanup-2stage-q4km.gguf",
       local_dir="~/.local/share/voxtype-cleanup/models".replace("~", __import__("os").path.expanduser("~")),
   )
   PY
   ```
   Point `voxtype-cleanupd` shebang at that venv. Start it. Then:
   ```bash
   /usr/lib/voxtype/voxtype-onnx-avx2 config set output.post_process.command "$HOME/.local/bin/voxtype-cleanup"
   systemctl --user restart voxtype
   ```
5. Voxtype OSD:
   ```bash
   ~/.local/bin/omarchy-voxtype-orb set jarvis
   ```
6. Hyprland: `hyprctl reload` then `hyprctl configerrors` (must be clean).
7. Verify autostart contains:
   - `omarchy-caelestia-start`
   - `omarchy-caelestia-wallpaper-watch`
   - `omarchy-os-haptics`
   - `omarchy-workspace-osd`
   - `voxtype-cleanupd`

## Do not copy from the source PC

- `~/.local/share/voxtype/models/` (hundreds of MB)
- `~/.local/share/voxtype-cleanup/models/*.gguf`
- Hermes/chat logs, tokens, `.ssh`

## Key overlay files

| Path | Role |
|---|---|
| `config/hypr/looknfeel.lua` | Gaps, rounding, blur; opacity locked at 1; workspace OSD layer rule |
| `config/hypr/bindings.lua` | Super+Backspace opacity cycle |
| `config/hypr/autostart.lua` | Extra processes; Omarchy shell still starts from defaults |
| `config/caelestia/shell.json` | Caelestia look (lock/osd off so Omarchy keeps those) |
| `bin/omarchy-sync-caelestia` | Map Omarchy theme colors → Caelestia |
| `bin/omarchy-os-haptics` | Kenney UI sounds on Hyprland events |
| `bin/omarchy-sounds` | Local settings UI at 127.0.0.1:17841 |
| `bin/omarchy-workspace-osd` | Named workspace toast |
| `config/omarchy-workspaces/names.json` | 1 Work … 9 Play … 10 Lab |
| `config/voxtype/osd/voxuirestyle` | Jarvis HUD, `palette = omarchy` |
| `config/systemd/user/voxtype.service.d/gpu.conf` | onnx-avx2 daemon |

## Known pitfalls

- `hyprctl dispatch renameworkspace` is Lua on this Omarchy. Overlay titles come from `names.json`, not Hyprland workspace names.
- Window-switch haptics stay **off** (`window_switch.enabled = false`).
- Whisper `small` + flash-attention on Intel HD 630 was slow (model re-init). Do not re-enable that.
- `voxtype setup --download --model parakeet-...` fails on the Vulkan binary (`parakeet feature not enabled`). Use `voxtype-onnx-avx2`.
- Encoder file is 652 183 999 bytes, sha256 `6139d2fa7e1b086097b277c7149725edbab89cc7c7ae64b23c741be4055aff09`. Voxtype's own curl may abort on slow links; resume with `curl -C -`.

## Acceptance checks

- Super+Space opens Omarchy launcher, Super+K opens keybind guide.
- Caelestia bar/background visible; Omarchy theme change recolors it.
- Workspace switch shows a title then fades.
- Right Alt dictation: Jarvis HUD, Parakeet in journal (`Loading Parakeet Tdt model`).
- `echo 'um so i i think we should ship this on uh friday' \| voxtype-cleanup` → `I think we should ship this on Friday.`
- Super+Space → System Sounds opens the sound app.
