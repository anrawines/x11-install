#!/bin/sh

firefox="${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox"
profiles="$firefox/profiles.ini"

firefox --headless >/dev/null 2>&1 &
sleep 1
pdir="$1"
profile="$(sed -n "/Default=.*.default-release/ s/.*=//p" "$profiles")"
[ -z "$1" ] && pdir="$firefox/$profile"

overrides="$2"
[ -z "$2" ] && overrides="$HOME/.config/firefox/user-overrides.js"

# Stop Firefox
pkill firefox

# Choose between Arkenfox and Betterfox
printf "\n=== Firefox Configuration ===\n"
printf "1. Arkenfox (privacy-focused, minimal)\n"
printf "2. Betterfox (privacy + UI/UX optimized)\n"
printf "Choose [1 or 2]: "
read -r choice

case "$choice" in
2)
  printf "Installing Betterfox...\n"
  betterfox="$pdir/betterfox-base.js"
  curl "https://raw.githubusercontent.com/yokoffing/Betterfox/refs/heads/main/user.js" >"$betterfox"
  userjs="$pdir/user.js"

  # Apply Betterfox + universal overrides + Betterfox-specific overrides
  cat "$betterfox" >"$userjs"
  [ -f "$overrides" ] && cat "$overrides" >>"$userjs"

  # Add Betterfox-specific overrides if available
  betterfox_overrides="$(dirname "$0")/betterfox-overrides.js"
  if [ -f "$betterfox_overrides" ]; then
    cat "$betterfox_overrides" >>"$userjs"
  fi
  printf "✓ Betterfox installed\n"
  ;;
*)
  printf "Installing Arkenfox...\n"
  arkenfox="$pdir/arkenfox.js"
  curl "https://raw.githubusercontent.com/arkenfox/user.js/master/user.js" >"$arkenfox"
  userjs="$pdir/user.js"
  cat "$arkenfox" >"$userjs"
  [ -f "$overrides" ] && cat "$overrides" >>"$userjs"

  # Add Betterfox-specific overrides if available
  betterfox_overrides="$(dirname "$0")/betterfox-overrides.js"
  if [ -f "$betterfox_overrides" ]; then
    cat "$betterfox_overrides" >>"$userjs"
  fi
  printf "✓ Arkenfox installed\n"
  ;;
esac

# Install Chrome customizations (UI CSS)
printf "\nInstalling Chrome customizations...\n"
chrome_src="$(dirname "$0")/chrome"
if [ -d "$chrome_src" ]; then
  mkdir -p "$pdir/chrome"
  [ -f "$chrome_src/userChrome.css" ] && cp "$chrome_src/userChrome.css" "$pdir/chrome/"
  [ -f "$chrome_src/userContent.css" ] && cp "$chrome_src/userContent.css" "$pdir/chrome/"
  printf "✓ Chrome customizations installed\n"
else
  printf "⚠ Chrome folder not found at %s\n" "$chrome_src"
fi

# Install extensions
addonlist="ublock-origin decentraleyes istilldontcareaboutcookies new-window-without-toolbar"
addontmp="$(mktemp -d)"
trap "rm -fr $addontmp" HUP INT QUIT TERM PWR EXIT
IFS=' '
mkdir -p "$pdir/extensions/"

# Loop through addons and install them
for addon in $addonlist; do
  # Get the direct download URL for the XPI file
  # This regex is an attempt to be more specific for XPI download links
  addon_download_page_url="https://addons.mozilla.org/en-US/firefox/addon/${addon}/"
  addonurl=$(curl -s "$addon_download_page_url" | grep -oE 'href="([^"]+/firefox/downloads/file/[^"]+\.xpi)"' | sed -E 's/href="([^"]+)"/\1/')

  if [ -z "$addonurl" ]; then
    echo "Could not find download URL for $addon. Skipping."
    continue
  fi

  # Extract filename from the URL
  file=$(basename "$addonurl")

  # Download the XPI file
  curl -L "$addonurl" -o "$addontmp/$file"

  if [ ! -f "$addontmp/$file" ]; then
    echo "Failed to download $addon.xpi. Skipping."
    continue
  fi

  # Get the addon ID from the manifest.json
  id=$(unzip -p "$addontmp/$file" manifest.json 2>/dev/null | sed -n 's/.*"id": *"\([^"]*\)".*/\1/p' | head -n 1)

  if [ -z "$id" ]; then
    echo "Could not find addon ID for $addon in its manifest. Skipping."
    continue
  fi

  # Move the .xpi file to the extensions directory with the correct ID
  mv "$addontmp/$file" "$pdir/extensions/$id.xpi"
  echo "✓ $addon installed as $id.xpi"
done
