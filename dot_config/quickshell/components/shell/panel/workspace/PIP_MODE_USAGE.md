# PIP Mode (Picture-in-Picture)

Component that enables a toggle-able floating picture-in-picture mode for windows in Niri.

## Features

- **Toggle behavior**: Press once to enable PIP, press again to return to normal
- Converts focused window to floating mode
- Resizes to 1/3 of screen width with 16:9 aspect ratio (like video content)
- Positions in bottom-right corner
- Returns window to tiling layout when toggled off

## Size & Position Details

- **Width**: 33% of screen width
- **Height**: 19% of screen height (maintains 16:9 aspect ratio)
- **Position**: Bottom-right corner
  - X: 67% (100% - 33%)
  - Y: 81% (100% - 19%)

## IPC Commands

### Enable/Toggle PIP Mode
```bash
qs ipc call ui.window.pip enable
```

Or use the alias:
```bash
qs ipc call ui.window.pip toggle
```

**Behavior**:
- If window is in tiling mode → Enables PIP mode
- If window is in PIP/floating mode → Returns to tiling mode

## Usage Examples

### With Niri Keybindings

Add to your `~/.config/niri/binds.kdl`:

```kdl
binds {
    // Toggle PIP mode with Super+I
    Mod+I hotkey-overlay-title="Window: PIP Mode" { 
        spawn-sh "uwsm app -- qs ipc call ui.window.pip enable"; 
    }
}
```

### Manual Testing

1. Focus a window you want in PIP mode (e.g., video player, terminal)
2. Run: `qs ipc call ui.window.pip enable`
3. The window will:
   - Become floating
   - Resize to 33% width × 19% height (16:9 ratio)
   - Move to bottom-right corner
4. Run the command again to return the window to normal tiling mode

## Technical Details

### Enable PIP (when window is tiling)
Executes the following Niri commands in sequence:

1. `niri msg action move-window-to-floating` - Make window floating
2. `niri msg action set-window-width '33%'` - Set width to 1/3 of screen
3. `niri msg action set-window-height '19%'` - Set height for 16:9 aspect ratio
4. `niri msg action move-floating-window --x '67%' --y '81%'` - Position at bottom-right

### Disable PIP (when window is floating)
Executes:

1. `niri msg action move-window-to-tiling` - Return window to tiling layout

## Use Cases

- Video playback while working on other tasks
- Monitoring terminal output
- Keeping chat/communication app visible
- Reference documentation while coding
- System monitoring dashboards

## Notes

- Only works on the currently focused window
- Window must support floating mode
- Position is relative to the current monitor
- Uses Niri's native floating window management
- Perfect for video content with 16:9 aspect ratio
