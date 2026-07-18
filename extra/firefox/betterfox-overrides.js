//
/* Betterfox-specific overrides and customizations
 * This file is applied AFTER the Betterfox base configuration
 * Customize these settings to your preferences
 */

/****************************************************************************
 * THEMING & UI CUSTOMIZATION
 ****************************************************************************/
// Enable custom CSS styling
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("svg.context-properties.content.enabled", true);

/****************************************************************************
 * TAB & WINDOW BEHAVIOR
 ****************************************************************************/
// Open new tabs/bookmarks in background
user_pref("browser.tabs.loadDivertedInBackground", true);
user_pref("browser.tabs.loadBookmarksInBackground", true);

// Keep window open when closing last tab
user_pref("browser.tabs.closeWindowWithLastTab", false);

// Session history limit
user_pref("browser.sessionhistory.max_entries", 6);

/****************************************************************************
 * VISUAL & INTERACTION PREFERENCES
 ****************************************************************************/
// Reduce motion animations
user_pref("ui.prefersReducedMotion", 1);

// Faster tooltip delay
user_pref("ui.tooltip.delay_ms", 25);
user_pref("browser.chrome.toolbar_tips", false);

// Disable tab and scrolling animations
user_pref("browser.tabs.animate", false);
user_pref("general.smoothScroll", false);

/****************************************************************************
 * MEDIA & DOWNLOAD BEHAVIOR
 ****************************************************************************/
// Download settings
user_pref("browser.download.manager.retention", 1);
user_pref("browser.download.alwaysOpenPanel", false);

// Media autoplay blocking
user_pref("image.animation_mode", "once");
user_pref("media.suspend-bkgnd-video.enabled", true);
user_pref("media.autoplay.default", 5);
user_pref("media.autoplay.blocking_policy", 2);
user_pref("media.block-autoplay-until-in-foreground", true);

/****************************************************************************
 * PERFORMANCE OPTIMIZATIONS
 ****************************************************************************/
// Enable WebRender acceleration
user_pref("gfx.webrender.all", true);

// Process count (increase for better performance)
user_pref("dom.ipc.processCount", 4);

// HTTP connection optimization
user_pref("network.http.max-persistent-connections-per-server", 10);
user_pref("network.http.pipelining", true);
user_pref("network.http.pipelining.maxrequests", 8);

/****************************************************************************
 * ADDITIONAL SECURITY
 ****************************************************************************/
// Disable AI/ML features
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.enable", false);

/****************************************************************************
 * END: BETTERFOX OVERRIDES
 ****************************************************************************/
