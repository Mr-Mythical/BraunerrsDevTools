# BraunerrsDevTools

A toolkit for World of Warcraft addon and WeakAura creators.

> ⚠️ **Early Development**: This addon is in early development. Features may change and bugs may occur.

## Dev Mode

The core feature of this addon is Dev Mode:
- Lets you use Ctrl+R (and optionally other modifier+R combos) to reload your UI, without interfering with your normal keybinds
- All reload keybinds are ignored while you are typing in chat or edit boxes (prevents accidental reloads while chatting and can be toggled in the options).
- Automatically enables BugSack error popups (if installed)
- Sets your character AFK to avoid interruptions
- Automatically enables debug modes in configured addons

Toggle Dev Mode at any time with `/bdt` or by creating a keybind in the settings.

### Configuration
Configure Dev Mode options through the game's interface options panel (Esc > Interface > AddOns > Braunerr's Dev Tools). Available settings include:
- Reload UI keybind combinations (Ctrl+R, Shift+R, Alt+R, etc.)
- BugSack integration
- Auto AFK when entering dev mode
- Addon debug integration
- Reload UI on dev mode toggle
- Disable reload keybinds while typing

### Debug Variables UI
When Dev Mode is active, a movable UI window appears showing all registered debug variables and their current status. This window provides a visual overview of which debug features are enabled and allows quick access to the Debug UI tool.

## Debug Variable Control

Easily control debug variables from any addon without code changes. This feature lets you toggle debug modes, verbose logging, and other boolean settings across all your addons through a user-friendly interface.

### What It Does
- **Universal Control**: Toggle any global boolean variable from any loaded addon
- **No Integration Required**: Works with existing addons automatically
- **Dev Mode Integration**: Auto-enable debug variables when entering dev mode
- **Persistent Settings**: Your debug configurations are saved and restored
- **Visual Interface**: UI window shows active variables when dev mode is enabled

### How It Works
Many addons use boolean variables for debug features (like `MyAddonDebug = true`). This system finds and controls these variables, giving you centralized debug management through the interface.

### Interface Usage
All debug variable management is handled through the UI window that appears when Dev Mode is active. From this window you can:
- View all registered debug variables and their current status
- Enable/disable individual variables
- Register/unregister variables for dev mode auto-toggle
- Access the Debug UI tool for advanced debugging

### For Addon Developers
Make your addon's debug features controllable by simply using global boolean variables:

```lua
-- In your addon
MyAddonDebug = false           -- Main debug toggle
MyAddonVerbose = false         -- Verbose logging
MyAddonTrace = false           -- Function tracing
```

Users can then control these variables through the BraunerrsDevTools interface when Dev Mode is active.

**Works with any global boolean variable from any loaded addon!**