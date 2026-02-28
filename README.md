# BraunerrsDevTools

**❤️ Support development on [Patreon](https://www.patreon.com/c/mrmythical)** - Help keep this and all our other addons updated and feature-rich!

---

A toolkit for World of Warcraft addon and WeakAura creators.

> ⚠️ **Early Development**: This addon is in early development. Features may change and bugs may occur.

## Key Features

### 🛠️ Dev Mode (`/bdt`)
The core feature of this addon. When toggled on, Dev Mode provides:
- **Unhindered UI Reloads**: Use `Ctrl+R` (or custom keybinds) to reload your UI. Keybinds are safely ignored while typing in chat or edit boxes.
- **Auto-AFK & BugSack Support**: Optionally sets your character AFK and automatically enables BugSack error popups to prevent interruptions.
- **Automatic Debugging**: Automatically enables your configured global addon debug modes.

*Settings for Dev Mode can be configured via Esc > Interface > AddOns > Braunerr's Dev Tools.*

### 🚀 Quick Action Tools
A suite of utilities designed to speed up common addon development tasks. Accessible via the **Quick Actions** floating window or slash commands:

- **Addon CPU Profiler** (`/bdt profiler`): A real-time tracking window listing all loaded addons sorted by CPU consumption (requires Profiling enabled).
- **Profile Toggle & Reload** (`/bdt profile`): Instantly toggles WoW's `scriptProfile` CVar and reloads your UI.
- **Screen Alignment Grid** (`/bdt grid [size]`): Overlays a visual grid center-screen for symmetrical UI element alignment.
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