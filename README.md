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

## Debug Variable Control

Easily control debug variables from any addon without code changes. This feature lets you toggle debug modes, verbose logging, and other boolean settings across all your addons.

### What It Does
- **Universal Control**: Toggle any global boolean variable from any loaded addon
- **No Integration Required**: Works with existing addons automatically
- **Dev Mode Integration**: Auto-enable debug variables when entering dev mode
- **Persistent Settings**: Your debug configurations are saved and restored

### How It Works
Many addons use boolean variables for debug features (like `MyAddonDebug = true`). This system finds and controls these variables, giving you centralized debug management.

### Commands
- `/bdt list` - Show all available debug variables from loaded addons
- `/bdt enable <variable>` - Turn on any debug variable (e.g., enable verbose logging)
- `/bdt disable <variable>` - Turn off any debug variable
- `/bdt register <variable>` - Add variable to dev mode auto-toggle list
- `/bdt unregister <variable>` - Remove from dev mode auto-toggle
- `/bdt enable/disable` - Control all registered variables at once

### Quick Examples
```bash
/bdt enable MyAddonDebug        # Enable debug logging in MyAddon
/bdt disable VerboseOutput      # Turn off verbose output
/bdt register MyAddonDebug      # Auto-enable when dev mode starts
/bdt list                       # See all debug variables available
```

### For Addon Developers
Make your addon's debug features controllable by simply using global boolean variables:

```lua
-- In your addon
MyAddonDebug = false           -- Main debug toggle
MyAddonVerbose = false         -- Verbose logging
MyAddonTrace = false           -- Function tracing

-- Developers can now control these with:
/bdt enable MyAddonDebug
/bdt enable MyAddonVerbose
```

**Works with any global boolean variable from any loaded addon!** No code changes required in BraunerrsDevTools.