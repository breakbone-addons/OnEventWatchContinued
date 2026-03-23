# OnEventWatch (Continued)

A profiling tool that estimates how long OnEvent handlers take to run, per frame.

Originally written by **Gello** in 2006 for vanilla WoW. This fork updates the addon to work with Burning Crusade Classic (and Anniversary Edition).

## Usage

Type `/onevent` to start watching. The addon enumerates all frames with OnEvent handlers and wraps them with `debugprofilestart()`/`debugprofilestop()` timing.

Type `/onevent` again to toggle the tracking window, which shows:

- **Frame** — the frame name (anonymous frames get numbered)
- **Event** — which event fired
- **Count** — how many times it fired
- **Time** — total estimated processing time
- **Avg** — average time per event

Click column headers to sort. Use the search boxes to filter by frame name or event name.

### Buttons

- **All** — clear search filters
- **Reset** — clear all collected data
- **Stop** — reload UI to remove all hooks
- **Ok** — close the window

### Tips

- Shift+click an event row to insert its stats into chat (for copy/paste)
- A minimap button appears as a reminder that hooks are active
- Due to microscopic times involved, treat measurements as comparative, not absolute
- This only watches OnEvent handlers. OnUpdate, OnClick, etc. are not captured.

## What Changed in v1.3

- Updated for BCC (Interface 20505)
- Replaced removed `this`/`event`/`arg1` implicit globals with explicit parameters
- Replaced `getglobal()` with `_G[]`
- Replaced `table.getn()`/`table.setn()` with `#` operator
- Added `BackdropTemplate` support
- Replaced `UIPanelButtonGrayTemplate` with `UIPanelButtonTemplate`
- Fixed `FauxScrollFrame_OnVerticalScroll` signature for BCC
- Updated `ChatFrameEditBox` reference for BCC chat system

## Installation

Extract to your `Interface/AddOns/` folder so the path is:
```
Interface/AddOns/OnEventWatch/OnEventWatch.toc
```

## Credits

- **Gello** — original author (v1.0–1.2, 2006)
- **Breakbone** — BCC update (v1.3)
