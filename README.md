# Mark that

Press a shortcut when you notice an Omarchy desktop glitch. Mark that captures the time, focused app, workspace, and up to 60 matching entries from the preceding minute of the user journal. Type or dictate what happened and press Enter to save the incident as a Markdown file.

## Install

On an Omarchy Quickshell desktop, run:

```sh
omarchy plugin add https://github.com/0xjoma/omarchy-mark-that.git --enable
```

The widget uses Python 3, Hyprland’s `hyprctl`, systemd’s `journalctl`, and `notify-send` for save notifications. Comparing incidents requires the Codex CLI and Omarchy’s terminal launcher. Dictation uses the input method you already have configured.

## Use

Click the flag on the bar to capture a mark. Right-click it to open **Recent marks**. To enable keyboard shortcuts, add these lines to `~/.config/hypr/bindings.lua`, choosing different keys if yours are already assigned.

```lua
o.bind("SUPER + CTRL + M", "Mark a desktop glitch", { panel = "joma.mark-that" })
o.bind("SUPER + R", "Show recent marks", { ipc = "joma.mark-that.toggleRecent" })
```

Recent marks shows the latest 50 saved incidents. Select at least two and choose **Compare in Codex** to start a read-only Codex session with the selected filenames. The initial prompt asks Codex to compare the evidence and distinguish patterns from established causes.

## Data

Capture runs when you mark an incident. It reads existing Hyprland, Omarchy shell, Quickshell, PipeWire, and WirePlumber journal entries from the current boot. Pressing Enter or choosing **Save mark** writes your note and the captured context to `$XDG_STATE_HOME/mark-that/marks/`, which defaults to `~/.local/state/mark-that/marks/`. Comparison is a separate action and uses your configured Codex service.

## Remove

```sh
omarchy plugin remove joma.mark-that
```

Remove any Mark that shortcuts you added to `bindings.lua`. Saved Markdown files are stored separately and remain available after uninstalling the plugin.
