# Firefox Configuration Setup

This folder provides automated setup for Firefox with security and customization profiles.

## Profiles

### 1. **Arkenfox** (Default)
Privacy-focused configuration with minimal UI customization. Best for users who want strong privacy settings without extensive customization.

- **Source**: [arkenfox/user.js](https://github.com/arkenfox/user.js)
- **Focus**: Privacy, security, tracking prevention
- **Minimal customization**: Uses standard Firefox UI

### 2. **Betterfox**
Comprehensive privacy configuration with enhanced UI/UX optimizations. Best for users who want privacy AND customization.

- **Source**: [yokoffing/Betterfox](https://github.com/yokoffing/Betterfox)
- **Focus**: Privacy + Performance + UI customization
- **Sections**: FastFox (speed), SecureFox (security), PeskyFox (UI), SmoothFox (scrolling)

## Usage

Run the setup script interactively:

```bash
./ff.sh
```

The script will:
1. Prompt you to choose between Arkenfox and Betterfox
2. Download and apply the selected configuration
3. Merge with your custom overrides
4. Install recommended extensions
5. Apply Chrome (UI CSS) customizations

## Customization Files

### `user-overrides.js`
Applied to **both** Arkenfox and Betterfox. Use this for universal preferences you want across both profiles.

### `betterfox-overrides.js`
Applied **only** when using Betterfox. Contains Betterfox-specific optimizations (UI animations, performance tuning, etc.)

### `chrome/`
Firefox UI customizations (userChrome.css, userContent.css):
- **userChrome.css**: Customizes Firefox UI elements (toolbar, tabs, addressbar)
- **userContent.css**: Customizes web content appearance (dark mode, layout fixes)

## Installation Steps

### Automatic (Recommended)
```bash
./ff.sh
```

### Manual (if needed)
```bash
# Choose your profile
# Option 1: Arkenfox
curl "https://raw.githubusercontent.com/arkenfox/user.js/master/user.js" > ~/.mozilla/firefox/PROFILE_DIR/user.js

# Option 2: Betterfox
curl "https://raw.githubusercontent.com/yokoffing/Betterfox/refs/heads/main/user.js" > ~/.mozilla/firefox/PROFILE_DIR/user.js

# Then apply your overrides
cat user-overrides.js >> ~/.mozilla/firefox/PROFILE_DIR/user.js
```

## Included Extensions

The setup automatically installs:
- **uBlock Origin** - Ad and tracker blocker
- **Decentraleyes** - Local CDN replacement
- **I Still Don't Care About Cookies** - Cookie banner blocker
- **New Window Without Toolbar** - Open new windows without toolbar

## Files

```
clean ff/
├── ff.sh                      # Main setup script
├── user-overrides.js          # Universal overrides (for both profiles)
├── betterfox-overrides.js     # Betterfox-specific overrides
├── betterfox-base.js          # Downloaded Betterfox base (auto-generated)
├── README.md                  # This file
└── chrome/
    ├── userChrome.css         # Firefox UI customizations
    └── userContent.css        # Web content customizations
```

## Differences: Arkenfox vs Betterfox

| Feature | Arkenfox | Betterfox |
|---------|----------|-----------|
| Privacy | ✅ Strong | ✅ Strong |
| Performance | ✅ Good | ✅✅ Optimized |
| UI Customization | Limited | Extensive |
| Animations | Default | Disabled |
| Scrolling | Default | Smooth |
| Tab Behavior | Default | Customized |
| Config Size | Smaller | Larger |
| Maintenance | Active | Active |

## Tips

- **First Time**: Choose Betterfox if you want the full customized experience
- **Minimal Setup**: Use Arkenfox for privacy without much tweaking
- **Custom Preferences**: Edit `user-overrides.js` for settings you want in both
- **Betterfox Only**: Edit `betterfox-overrides.js` for Betterfox-specific tweaks
- **CSS Theming**: Modify `chrome/*.css` files for UI appearance changes

## Important Notes

⚠️ These configurations disable telemetry, crash reporting, and most Mozilla services.

⚠️ If you have custom `about:config` preferences, **back them up first** - these profiles will override them.

⚠️ Changes to `user.js` are applied when Firefox starts. Close Firefox completely before running `./ff.sh`.

## Resources

- [Arkenfox Documentation](https://github.com/arkenfox/user.js/wiki)
- [Betterfox Wiki](https://github.com/yokoffing/Betterfox/wiki)
- [Firefox Privacy Guide](https://www.privacytools.io/browsers/#firefox)
- [Firefox CSS Documentation](https://www.userchrome.org/)
