# BraunerrsDevTools

**❤️ Support development on [Patreon](https://www.patreon.com/c/mrmythical)** - Help keep this and all our other addons updated and feature-rich!

---

BraunerrsDevTools speeds up World of Warcraft addon and WeakAura development with Dev Mode (safe reloads, AFK/BugSack support, auto debug toggles), Quick Actions (profiler, grid, coords, profile toggle), and universal debug variable control.

> ⚠️ **Early Development**: This addon is in early development. Features may change and bugs may occur.

## Key Features

### 🛠️ Dev Mode (`/bdt`)
The core feature of this addon. When toggled on, Dev Mode provides:
- **Unhindered UI Reloads**: Use `Ctrl+R` by default (or enable `R`, `Shift+R`, and `Alt+R` variants in settings) to reload your UI. Keybinds are ignored while typing in chat or edit boxes.
- **Auto-AFK & BugSack Support**: Optionally sets your character AFK and automatically enables BugSack error popups to prevent interruptions.
- **Automatic Debugging**: Automatically enables your configured global addon debug modes.
- **Saved Tool Positions**: Quick Actions, Active Debug Variables, and Mouse Coordinates remember where you moved them and can be reset with `/bdt resetui`.

*Settings for Dev Mode can be configured via Esc > Interface > AddOns > Braunerr's Dev Tools.*

### 🚀 Quick Action Tools
A suite of utilities designed to speed up common addon development tasks. Accessible via the **Quick Actions** floating window and slash commands:

- **Addon CPU Profiler** (`/bdt profiler`): A real-time tracking window listing all loaded addons sorted by CPU consumption (requires Profiling enabled).
- **Profile Toggle & Reload** (`/bdt profile`): Instantly toggles WoW's `scriptProfile` CVar and reloads your UI.
- **Quick Actions Panel** (`/bdt quick`): Opens or closes the floating action palette.
- **Screen Alignment Grid** (`/bdt grid [size|off]`): Overlays a visual grid center-screen for symmetrical UI element alignment.
- **Mouse Coordinates Overlay** (`/bdt coords`): Tracks precise X and Y coordinates (both Raw Screen and UIParent scaled).
- **Clear Chat** (`/cc` or `/clearchat`): Instantly wipes all chat windows clean.
- **Blizzard API Toggles**: Quick UI buttons for `/fstack` and `/etrace`.

### 🎛️ Universal Debug Variable Control
Easily control any global boolean variable (e.g., `MyAddonDebug = true`) across *all* addons through a unified visual interface. 

The **Active Debug Variables** UI (which opens alongside Dev Mode) allows you to:
- View all active boolean variables from loaded addons.
- Enable or disable individual variables without altering code.
- Register specific variables to automatically toggle `ON` when Dev Mode is active.

#### For Addon Developers
Make your addon's debug features controllable simply by declaring a global boolean:

```lua
MyAddonDebug = false    -- Main debug toggle
MyAddTrace = false      -- Function tracing
```
You can now immediately control these properties when Dev Mode is active!

## Slash Commands

- `/bdt` - Toggle Dev Mode.
- `/bdt quick` - Toggle the Quick Actions panel.
- `/bdt debug` - Open the debug variable browser directly.
- `/bdt check <variable>` - Inspect a global variable and show whether it can be registered.
- `/bdt coords` - Toggle the mouse coordinates overlay.
- `/bdt grid [size|off]` - Toggle, resize, or disable the grid overlay.
- `/bdt profile` - Toggle `scriptProfile` and reload the UI.
- `/bdt profiler` - Toggle the addon CPU/memory profiler.
- `/bdt resetui` - Reset saved BDT tool window positions.
- `/bdt help` - Print the command list in chat.
- `/cc` or `/clearchat` - Clear all chat windows.
