# Firefox Setup - Arkenfox vs Betterfox

## What Changed

This update adds **Betterfox** as an alternative to Arkenfox with an interactive choice menu.

### New Files Created

1. **ff.sh** (updated)
   - Added interactive menu to choose between Arkenfox and Betterfox
   - Now installs Chrome customizations automatically
   - Supports Betterfox-specific overrides

2. **betterfox-base.js** (auto-generated)
   - Downloaded from Betterfox repo on first run
   - Contains full Betterfox configuration

3. **betterfox-overrides.js** (new)
   - Betterfox-specific customizations
   - Applied only when choosing Betterfox
   - Includes UI animations, performance tuning, media controls

4. **README.md** (new)
   - Complete documentation
   - Comparison table: Arkenfox vs Betterfox
   - Installation instructions and tips

5. **chrome/** (enhanced)
   - userChrome.css (UI customizations)
   - userContent.css (web content customizations)
   - Now automatically installed by ff.sh

## Quick Start

### Option 1: Arkenfox (Recommended for minimal setup)
```bash
cd extra/clean\ ff/
./ff.sh
# Choose option 1 when prompted
```

### Option 2: Betterfox (Recommended for full customization)
```bash
cd extra/clean\ ff/
./ff.sh
# Choose option 2 when prompted
```

## Configuration Layers

The setup applies configurations in this order:

### For Arkenfox:
```
Arkenfox Base (from repo)
        ↓
User Overrides (universal)
        ↓
user.js (final)
```

### For Betterfox:
```
Betterfox Base (from repo)
        ↓
User Overrides (universal)
        ↓
Betterfox Overrides (specific)
        ↓
user.js (final)
```

## Files Overview

| File | Purpose | Applies To |
|------|---------|-----------|
| user-overrides.js | Universal preferences | Both Arkenfox & Betterfox |
| betterfox-overrides.js | Betterfox-specific tuning | Betterfox only |
| chrome/userChrome.css | Firefox UI customizations | Both profiles |
| chrome/userContent.css | Web page appearance | Both profiles |

## Customization

### To change universal settings:
Edit `user-overrides.js` - applies to both profiles

### To customize Betterfox only:
Edit `betterfox-overrides.js` - only applies when choosing Betterfox

### To customize Firefox UI:
Edit `chrome/userChrome.css` for toolbar, tabs, address bar, etc.

### To customize web pages:
Edit `chrome/userContent.css` for page backgrounds, fonts, layouts, etc.

## What Gets Installed

### Configuration (`user.js`)
- Strong privacy settings
- Tracking protection
- Telemetry disabled
- Security hardening

### Chrome Customizations
- Dark UI theme
- Optimized toolbar layout
- Custom tab styling
- Dark web page backgrounds

### Extensions
1. **uBlock Origin** - Ad/tracker blocker
2. **Decentraleyes** - CDN replacement (privacy)
3. **I Still Don't Care About Cookies** - Cookie banner blocker
4. **New Window Without Toolbar** - Clean new window option

## Key Differences

### Arkenfox
- Minimal UI changes
- Privacy-focused
- Lighter configuration
- Official Firefox look

### Betterfox
- Comprehensive UI customization
- Privacy + Performance optimizations
- Disabled animations for speed
- Dark theme by default
- Tab behavior customization
- Media autoplay blocking

## Troubleshooting

### Extensions won't install
```bash
# Check internet connection
# Try running again
./ff.sh
```

### Chrome customizations not applied
```bash
# Verify user.js contains:
# user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

# Check chrome directory exists:
ls -la ~/.mozilla/firefox/*/chrome/
```

### Want to switch profiles later
```bash
# Just run ff.sh again and choose the other option
./ff.sh
```

### Remove all customizations
```bash
# Remove user.js and chrome folder
rm ~/.mozilla/firefox/PROFILE/user.js
rm -rf ~/.mozilla/firefox/PROFILE/chrome
# Firefox will use default settings
```

## Resources

- [Betterfox GitHub](https://github.com/yokoffing/Betterfox)
- [Arkenfox GitHub](https://github.com/arkenfox/user.js)
- [Firefox CSS Customization](https://www.userchrome.org/)
- [Firefox Privacy Guide](https://privacytools.io/browsers/#firefox)
