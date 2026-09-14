# Omarchy + Caelestia kit

User overlay for an Omarchy Linux PC: Caelestia visuals, Omarchy keybinds,
Kenney system sounds, Jarvis dictation HUD, Parakeet ASR, and a tiny
transcript-cleanup model.

This is **not** a fork of Omarchy. It only ships files that live in `$HOME`.

## For other agents

Read [`AGENT.md`](AGENT.md) and run `./install.sh` on a machine that already
has Omarchy installed. Do not edit `/usr/share/omarchy/`.

## For humans

```bash
git clone <this-repo> ~/Projects/omarchy-caelestia-kit
cd ~/Projects/omarchy-caelestia-kit
./install.sh
```

Then log out and back in (or reboot) so Hyprland autostart picks up the extra
processes.

## What you get

| Piece | What it does |
|---|---|
| Caelestia shell | Look only. Super+Space, Super+K, lock stay Omarchy |
| Theme sync | Caelestia colors + wallpaper follow Omarchy theme |
| Super+Backspace | Per-window opacity 100→90→80→70 |
| System Sounds | Super+Space → System Sounds. Kenney CC0 clicks |
| Workspace titles | Named toast on workspace switch, then fade |
| Jarvis HUD | Dictation orb, Omarchy palette |
| Parakeet TDT 0.6B int8 | ASR engine instead of Whisper base.en |
| mumble-cleanup 0.5B | Cleans fillers/punctuation before typing |

## Switch the dictation orb

```
omarchy-voxtype-orb list
omarchy-voxtype-orb set jarvis      # default, renders
omarchy-voxtype-orb set dictator    # dithered ring (experimental)
omarchy-voxtype-orb set omarchy     # compact bar
```

## Edit workspace names

`~/.config/omarchy-workspaces/names.json`

Default: 1 Work, 2 Code, 3 Web, 4 Write, 5 Chat, 6 Mail, 7 Files, 8 Make, 9 Play, 0/10 Lab.

## License

Scripts: MIT.
Kenney Interface Sounds in `share/omarchy-haptics/library/`: CC0.
VoxUiRestyle / voxtype-osd-omarchy: keep upstream licenses.
