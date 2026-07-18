-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors,
    })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        -- Make sure we don't go into an endless error loop
        if in_error then
            return
        end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err),
        })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Seed the random number generator
math.randomseed(os.time())

-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_configuration_dir() .. "theme/gruvbox/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "alacritty"
fileman = "thunar"
browser = "firefox"
guiedit = "geany"

editor = os.getenv("EDITOR") or "nvim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
    {
        "hotkeys",
        function()
            hotkeys_popup.show_help(nil, awful.screen.focused())
        end,
    },
    { "manual", terminal .. " -e man awesome" },
    { "edit config", editor_cmd .. " " .. awesome.conffile },
    { "restart", awesome.restart },
    {
        "quit",
        function()
            awesome.quit()
        end,
    },
}

mymainmenu = awful.menu({
    items = {
        { "awesome", myawesomemenu, beautiful.awesome_icon },
        { "open terminal", terminal },
        { "open browser", browser },
        { "open fileman", fileman },
    },
})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
-- mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock('%a %d %b, %H:%M')

local month_calendar = awful.widget.calendar_popup.month(os.date('*t'))
month_calendar:attach(mytextclock, "tr")

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t)
        t:view_only()
    end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({}, 4, function(t)
        awful.tag.viewnext(t.screen)
    end),
    awful.button({}, 5, function(t)
        awful.tag.viewprev(t.screen)
    end)
)

local function set_wallpaper(s)
    -- Wallpaper path
    local wp_dir = os.getenv("HOME") .. "/Pictures/wallpapers"

    -- Get list of wallpapers
    local f = io.popen(
        'find "'
            .. wp_dir
            .. '" -maxdepth 1 -type f \\( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \\) 2>/dev/null'
    )
    local files = {}
    if f then
        for line in f:lines() do
            table.insert(files, line)
        end
        f:close()
    end

    local wallpaper
    if #files > 0 then
        -- Pick a random one from the directory
        wallpaper = files[math.random(#files)]
    elseif beautiful.wallpaper then
        -- Fallback to theme wallpaper
        wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
    end

    if wallpaper then
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ " 1 ", " 2 ", " 3 ", " 4 ", " 5 ", " 6 ", " 7 ", " 8 ", " 9 " }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.layout.inc(1)
        end),
        awful.button({}, 3, function()
            awful.layout.inc(-1)
        end),
        awful.button({}, 4, function()
            awful.layout.inc(1)
        end),
        awful.button({}, 5, function()
            awful.layout.inc(-1)
        end)
    ))

    -- Helper function to wrap widgets with background and margins
    local function wrap_widget(widget, bg_color, h_margin, v_margin)
        return wibox.container.background(
            wibox.container.place(
                wibox.container.margin(widget, h_margin or 4, h_margin or 4, v_margin or 0, v_margin or 0)
            ),
            bg_color or "#98971a",
            gears.shape.rectangle
        )
    end

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist({
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
    })

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist({
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
    })

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", ontop = false ,screen = s, height = beautiful.wibar_height or 32 })

    -- Custom System Widgets
    -- CPU
    local cpu_widget = awful.widget.watch(
        'bash -c "read -r _ u n s i o _ < /proc/stat; sleep 0.5; read -r _ u2 n2 s2 i2 o2 _ < /proc/stat; total=$(( (u2+n2+s2+i2+o2) - (u+n+s+i+o) )); active=$(( (u2+n2+s2+o2) - (u+n+s+o) )); echo $((100*active/total))%"',
        2,
        function(widget, stdout)
            widget:set_text("  " .. stdout:gsub("\n", "") .. " ")
        end
    )

    -- RAM
    local ram_widget = awful.widget.watch(
        'bash -c "free -m | awk \'/Mem:/ {printf(\\"%.1fG/%.1fG\\", $3/1024, $2/1024)}\'"',
        5,
        function(widget, stdout)
            widget:set_text("  " .. stdout:gsub("\n", "") .. " ")
        end
    )

    -- Network (Left click opens nmtui)
    local net_widget = awful.widget.watch(
        "bash -c \"ip route get 1.1.1.1 | grep -Po '(?<=dev )\\S+' | xargs ip addr show | grep -Po '(?<=inet )\\S+' | cut -d/ -f1\"",
        15,
        function(widget, stdout)
            local ip = stdout:gsub("\n", "")
            if ip == "" then
                ip = "Disconnected"
            end
            widget:set_text("  " .. ip .. " ")
        end
    )
    net_widget:buttons(gears.table.join(awful.button({}, 1, function()
        awful.spawn(terminal .. " -e nmtui")
    end)))

    -- Brightness (Scroll to adjust)
    local bright_widget = awful.widget.watch(
        "bash -c \"brightnessctl info | grep -Po '(?<=\\()\\d+(?=%)'\"",
        5,
        function(widget, stdout)
            widget:set_text(" 󰃠 " .. stdout:gsub("\n", "") .. "% ")
        end
    )
    bright_widget:buttons(gears.table.join(
        awful.button({}, 4, function()
            awful.spawn("brightnessctl set 5%+", false)
            bright_widget:emit_signal("timeout")
        end),
        awful.button({}, 5, function()
            awful.spawn("brightnessctl set 5%-", false)
            bright_widget:emit_signal("timeout")
        end)
    ))

    -- Volume (Mute detection, Left click pavucontrol, Right click mute)
    local vol_widget = awful.widget.watch(
        "bash -c \"pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\\d+%' | head -1; pactl get-sink-mute @DEFAULT_SINK@\"",
        1,
        function(widget, stdout)
            local vol = stdout:match("(%d+%%)") or "N/A"
            local mute = stdout:match("Mute: yes")
            local icon = mute and " 󰝟 " or "  "
            widget:set_text(icon .. vol .. " ")
        end
    )
    vol_widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.spawn("pavucontrol")
        end),
        awful.button({}, 3, function()
            awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
            vol_widget:emit_signal("timeout")
        end),
        awful.button({}, 4, function()
            awful.spawn.with_shell(
                "pactl set-sink-volume @DEFAULT_SINK@ +5%; if [ $(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]\\+%' | head -1 | tr -d '%') -gt 145 ]; then pactl set-sink-volume @DEFAULT_SINK@ 145%; fi"
            )
            vol_widget:emit_signal("timeout")
        end),
        awful.button({}, 5, function()
            awful.spawn.with_shell("pactl set-sink-volume @DEFAULT_SINK@ -5%")
            vol_widget:emit_signal("timeout")
        end)
    ))

    -- Focused Window Widget (Icon + Title)
    local focused_window_widget = wibox.widget({
        {
            {
                id = "icon_role",
                widget = wibox.widget.imagebox,
            },
            margins = 4,
            widget = wibox.container.margin,
        },
        {
            id = "text_role",
            widget = wibox.widget.textbox,
        },
        layout = wibox.layout.fixed.horizontal,
    })

    client.connect_signal("focus", function(c)
        focused_window_widget:get_children_by_id("icon_role")[1].image = c.icon
        focused_window_widget:get_children_by_id("text_role")[1].text = " " .. (c.name or "")
    end)
    client.connect_signal("unfocus", function()
        focused_window_widget:get_children_by_id("icon_role")[1].image = nil
        focused_window_widget:get_children_by_id("text_role")[1].text = ""
    end)

    -- Add widgets to the wibox
    s.mywibox:setup({
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            -- awesome icon size
            wrap_widget(mylauncher, "#98971a", 4, 4),
            s.mytaglist,
            -- layout icon size
            wrap_widget(s.mylayoutbox, "#98971a", 2, 2),
        },
        { -- Middle: Focused Window Icon and Title
            focused_window_widget,
            valign = "left",
            halign = "left",
            layout = wibox.container.place,
        },
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            {
                wibox.widget.systray(),
                top = 6,
                bottom = 6,
                left = 4,
                right = 4,
                widget = wibox.container.margin,
            },
            wrap_widget(cpu_widget),
            wrap_widget(ram_widget),
            wrap_widget(net_widget),
            wrap_widget(mytextclock, "#282828"), -- Standout color for clock
            wrap_widget(bright_widget),
            wrap_widget(vol_widget),
        },
    })
end)
-- }}}-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    -- awful.button({}, 3, function()
    --     mymainmenu:toggle()
    -- end),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Scratchpad logic
local function toggle_scratchpad(cmd, instance)
    local screen = awful.screen.focused()
    local scratch_client = nil
    for _, c in ipairs(client.get()) do
        if c.instance == instance then
            scratch_client = c
            break
        end
    end

    if not scratch_client then
        awful.spawn(cmd)
    else
        if scratch_client.minimized then
            scratch_client:move_to_tag(screen.selected_tag)
            scratch_client.minimized = false
            awful.placement.centered(scratch_client, {honor_workarea = true})
            scratch_client:raise()
            client.focus = scratch_client
        elseif scratch_client.first_tag ~= screen.selected_tag then
            scratch_client:move_to_tag(screen.selected_tag)
            awful.placement.centered(scratch_client, {honor_workarea = true})
            scratch_client:raise()
            client.focus = scratch_client
        else
            scratch_client.minimized = true
        end
    end
    return scratch_client
end
-- }}}


-- {{{ Key bindings
-- GLOBAL KEY
globalkeys = gears.table.join(
    awful.key({ modkey }, "/", hotkeys_popup.show_help, { description = "show help", group = "awesome" }),

    awful.key({ modkey }, "Left", awful.tag.viewprev, { description = "view previous", group = "tag" }),
    awful.key({ modkey }, "Right", awful.tag.viewnext, { description = "view next", group = "tag" }),
    awful.key({ modkey }, "`", awful.tag.history.restore, { description = "go back", group = "tag" }),

    -- Toggle Bar On/Off
    awful.key({ modkey }, "F2", function()
      local s = awful.screen.focused()
      s.mywibox.visible = not s.mywibox.visible
    end, { description = "toggle bar", group = "awesome" }),

    -- Show Menu Awesome
    awful.key({ modkey }, "w", function()
        mymainmenu:show()
    end, { description = "show main menu", group = "awesome" }),

    -- Increase gaps to 5px
    --awful.key({ modkey }, "=", function()
    --s.selected_tag.gap = "5"
    --end, { description = "set gap 5", group = "awesome"}),

    -- FOCUS
    awful.key({ modkey }, "j", function()
        awful.client.focus.byidx(1)
    end, { description = "focus next by index", group = "client" }),
    awful.key({ modkey }, "k", function()
        awful.client.focus.byidx(-1)
    end, { description = "focus previous by index", group = "client" }),
    awful.key({ modkey }, "h", function()
        awful.client.focus.bydirection("left")
    end, { description = "focus left by index", group = "client" }),
    awful.key({ modkey }, "l", function()
        awful.client.focus.bydirection("right")
    end, { description = "focus right by index", group = "client" }),
    -- support arrow keys for focus
    awful.key({ modkey }, "Down", function()
        awful.client.focus.byidx(1)
    end, { description = "focus next by index", group = "client" }),
    awful.key({ modkey }, "Up", function()
        awful.client.focus.byidx(-1)
    end, { description = "focus previous by index", group = "client" }),

    -- SWAP ( WIN + CONTROL + xx )
    awful.key({ modkey, "Control" }, "j", function()
        awful.client.swap.byidx(1)
    end, { description = "swap with next client by index", group = "client" }),
    awful.key({ modkey, "Control" }, "k", function()
        awful.client.swap.byidx(-1)
    end, { description = "swap with previous client by index", group = "client" }),
    awful.key({ modkey, "Control" }, "Down", function()
        awful.client.swap.byidx(1)
    end, { description = "swap with next client by index", group = "client" }),
    awful.key({ modkey, "Control" }, "Up", function()
        awful.client.swap.byidx(-1)
    end, { description = "swap with previous client by index", group = "client" }),

    awful.key({ modkey, "Control" }, "h", function()
        awful.tag.incnmaster(1, nil, true)
    end, { description = "increase number of masters", group = "layout" }),
    awful.key({ modkey, "Control" }, "l", function()
        awful.tag.incnmaster(-1, nil, true)
    end, { description = "decrease number of masters", group = "layout" }),
    awful.key({ modkey, "Control" }, "Left", function()
        awful.tag.incnmaster(1, nil, true)
    end, { description = "increase number of masters", group = "layout" }),
    awful.key({ modkey, "Control" }, "Right", function()
        awful.tag.incnmaster(-1, nil, true)
    end, { description = "decrease number of masters", group = "layout" }),

    -- Resize vim keys + arrow keys
    awful.key({ modkey, "Shift" }, "l", function()
        awful.tag.incmwfact(0.05)
    end, { description = "increase master width factor", group = "layout" }),
    awful.key({ modkey, "Shift" }, "h", function()
        awful.tag.incmwfact(-0.05)
    end, { description = "decrease master width factor", group = "layout" }),
    awful.key({ modkey, "Shift" }, "j", function()
        pcall(function() awful.client.incwfact(0.05) end)
    end, { description = "increase client height factor", group = "layout" }),
    awful.key({ modkey, "Shift" }, "k", function()
        pcall(function() awful.client.incwfact(-0.05) end)
    end, { description = "decrease client height factor", group = "layout" }),

    awful.key({ modkey, "Shift" }, "Right", function()
        awful.tag.incmwfact(0.05)
    end, { description = "increase master width factor", group = "layout" }),
    awful.key({ modkey, "Shift" }, "Left", function()
        awful.tag.incmwfact(-0.05)
    end, { description = "decrease master width factor", group = "layout" }),
    awful.key({ modkey, "Shift" }, "Down", function()
        pcall(function() awful.client.incwfact(0.05) end)
    end, { description = "increase client height factor", group = "layout" }),
    awful.key({ modkey, "Shift" }, "Up", function()
        pcall(function() awful.client.incwfact(-0.05) end)
    end, { description = "decrease client height factor", group = "layout" }),

    -- Move/Resize floating windows ( SUPER + ALT + xx )
    awful.key({ modkey, "Mod1" }, "j", function () awful.client.moveresize( 0,  40, 0, 0) end,
              {description = "move floating south", group = "client"}),
    awful.key({ modkey, "Mod1" }, "k", function () awful.client.moveresize( 0, -40, 0, 0) end,
              {description = "move floating north", group = "client"}),
    awful.key({ modkey, "Mod1" }, "h", function () awful.client.moveresize(-40,  0, 0, 0) end,
              {description = "move floating west", group = "client"}),
    awful.key({ modkey, "Mod1" }, "l", function () awful.client.moveresize( 40,  0, 0, 0) end,
              {description = "move floating east", group = "client"}),

    awful.key({ modkey, "Mod1", "Control" }, "j", function () awful.client.moveresize( 0, 0, 0,  40) end,
              {description = "resize floating taller", group = "client"}),
    awful.key({ modkey, "Mod1", "Control" }, "k", function () awful.client.moveresize( 0, 0, 0, -40) end,
              {description = "resize floating shorter", group = "client"}),
    awful.key({ modkey, "Mod1", "Control" }, "h", function () awful.client.moveresize( 0, 0, -40, 0) end,
              {description = "resize floating narrower", group = "client"}),
    awful.key({ modkey, "Mod1", "Control" }, "l", function () awful.client.moveresize( 0, 0,  40, 0) end,
              {description = "resize floating wider", group = "client"}),

    -- Scratchpad
    awful.key({ modkey }, "s", function ()
        toggle_scratchpad(terminal .. " --class scratchpad", "scratchpad")
    end,
    {description = "toggle scratchpad", group = "launcher"}),



    -- SWAP
    --awful.key({ modkey, "Shift" }, "j", function()
    --    awful.client.swap.byidx(1)
    --end, { description = "swap with next client by index", group = "client" }),
    --awful.key({ modkey, "Shift" }, "k", function()
    --    awful.client.swap.byidx(-1)
    --end, { description = "swap with previous client by index", group = "client" }),

    -- FOCUS DUAL SCREEN
    --awful.key({ modkey, "Control" }, "j", function()
    --    awful.screen.focus_relative(1)
    --end, { description = "focus the next screen", group = "screen" }),
    --awful.key({ modkey, "Control" }, "k", function()
    --    awful.screen.focus_relative(-1)
    --end, { description = "focus the previous screen", group = "screen" }),

    awful.key({ modkey }, "u", awful.client.urgent.jumpto, { description = "jump to urgent client", group = "client" }),
    awful.key({ modkey }, "Tab", function()
        awful.client.focus.history.previous()
        if client.focus then
            client.focus:raise()
        end
    end, { description = "go back", group = "client" }),

    -- toggle floating
    awful.key({ modkey}, "t",
        function()
        awful.client.floating.toggle()
        awful.placement.centered()
        end,
        {
        description = "toggle floating",
        group = "client",
    }),

    -- Standard program
    awful.key({ modkey }, "Return", function()
        awful.spawn(terminal)
    end, { description = "open a terminal", group = "launcher" }),

    awful.key({ modkey }, "e", function()
        awful.spawn(fileman)
    end, { description = "gui file manager", group = "fileman" }),

    awful.key({ modkey }, "b", function()
        awful.spawn(browser)
    end, { description = "browser", group = "browser" }),

    awful.key({ modkey }, "g", function()
        awful.spawn(guiedit)
    end, { description = "gui editor", group = "editor" }),

    awful.key({ modkey, "Shift" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "q", awesome.quit, { description = "quit awesome", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "b", function ()
        for s in screen do
            s.mywibox.visible = not s.mywibox.visible
        end
    end, {description = "toggle wibar", group = "awesome"}),

    -- Layout
    awful.key({ modkey }, "F1", function()
        awful.layout.inc(1)
    end, { description = "select next", group = "layout" }),

    awful.key({ modkey, "Shift" }, "F1", function()
        awful.layout.inc(-1)
    end, { description = "select previous", group = "layout" }),

    -- Minimize
    awful.key({ modkey, "Control" }, "n", function()
        local c = awful.client.restore()
    -- Focus restored client
        if c then
            c:emit_signal("request::activate", "key.unminimize", { raise = true })
        end
    end, { description = "restore minimized", group = "client" }),

    -- Prompt
    awful.key({ modkey }, "r", function()
        awful.screen.focused().mypromptbox:run()
    end, { description = "run prompt", group = "launcher" }),

    awful.key({ modkey }, "x", function()
        awful.prompt.run({
            prompt = "Run Lua code: ",
            textbox = awful.screen.focused().mypromptbox.widget,
            exe_callback = awful.util.eval,
            history_path = awful.util.get_cache_dir() .. "/history_eval",
        })
    end, { description = "lua execute prompt", group = "awesome" }),

    -- Menubar
    awful.key({ modkey }, "d", function()
        menubar.show()
    end, { description = "show the menubar", group = "launcher" }),

    -- Monitor Setup Toggle
    awful.key({ modkey, "Control" }, "p", function()
        awful.spawn.with_shell("~/.config/awesome/monitor_setup.sh")
    end, { description = "refresh monitor setup", group = "screen" }),

    -- Multimedia Keys
    awful.key({}, "XF86AudioRaiseVolume", function()
        awful.spawn.with_shell(
            "pactl set-sink-volume @DEFAULT_SINK@ +5%; if [ $(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]\\+%' | head -1 | tr -d '%') -gt 145 ]; then pactl set-sink-volume @DEFAULT_SINK@ 145%; fi"
        )
        if vol_widget then
            vol_widget:emit_signal("timeout")
        end
    end, { description = "increase volume", group = "media" }),
    awful.key({}, "XF86AudioLowerVolume", function()
        awful.spawn.with_shell("pactl set-sink-volume @DEFAULT_SINK@ -5%")
        if vol_widget then
            vol_widget:emit_signal("timeout")
        end
    end, { description = "decrease volume", group = "media" }),
    awful.key({}, "XF86AudioMute", function()
        awful.spawn.with_shell("pactl set-sink-mute @DEFAULT_SINK@ toggle")
        if vol_widget then
            vol_widget:emit_signal("timeout")
        end
    end, { description = "mute volume", group = "media" }),
    awful.key({}, "XF86AudioPlay", function()
        awful.spawn("playerctl play-pause", false)
    end, { description = "play/pause", group = "media" }),
    awful.key({}, "XF86AudioNext", function()
        awful.spawn("playerctl next", false)
    end, { description = "next track", group = "media" }),
    awful.key({}, "XF86AudioPrev", function()
        awful.spawn("playerctl previous", false)
    end, { description = "previous track", group = "media" }),
    awful.key({}, "XF86AudioStop", function()
        awful.spawn("playerctl stop", false)
    end, { description = "stop track", group = "media" }),

    -- Brightness Keys
    awful.key({}, "XF86MonBrightnessUp", function()
        awful.spawn("brightnessctl set 5%+", false)
    end, { description = "increase brightness", group = "media" }),
    awful.key({}, "XF86MonBrightnessDown", function()
        awful.spawn("brightnessctl set 5%-", false)
    end, { description = "decrease brightness", group = "media" })
)

-- CLIENT KEY
clientkeys = gears.table.join(
    awful.key({ modkey }, "space", function(c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end, { description = "toggle fullscreen", group = "client" }),

    awful.key({ modkey }, "q", function(c)
        c:kill()
    end, { description = "close", group = "client" }),

    awful.key(
        { modkey, "control" },"space", function(c)
        awful.client.floating.toggle()
    end,{ description = "toggle floating", group = "client" }),


    awful.key({ modkey, "control" }, "Return", function(c)
        c:swap(awful.client.getmaster())
    end, { description = "move to master", group = "client" }),

    awful.key({ modkey }, "o", function(c)
        c:move_to_screen()
    end, { description = "move to screen", group = "client" }),

    awful.key({ modkey }, "i", function(c)
        c.ontop = not c.ontop
    end, { description = "toggle keep on top", group = "client" }),

    awful.key({ modkey, "Shift" }, "t", function(c)
        awful.titlebar.toggle(c)
    end, { description = "toggle titlebar", group = "client" }),

    awful.key({ modkey }, "n", function(c)
        -- The client currently has the input focus, so it cannot be
        -- minimized, since minimized clients can't have the focus.
        c.minimized = true
    end, { description = "minimize", group = "client" }),

    awful.key({ modkey }, "m", function(c)
        c.maximized = not c.maximized
        c:raise()
    end, { description = "(un)maximize", group = "client" }),

    awful.key({ modkey, "Control" }, "m", function(c)
        c.maximized_vertical = not c.maximized_vertical
        c:raise()
    end, { description = "(un)maximize vertically", group = "client" }),

    awful.key({ modkey, "Shift" }, "m", function(c)
        c.maximized_horizontal = not c.maximized_horizontal
        c:raise()
    end, { description = "(un)maximize horizontally", group = "client" })
)

-- Bind all key numbers to tags (Top Row and Numpad).
local num_keys = {
    { key = "1", kp = "KP_End", index = 1 },
    { key = "2", kp = "KP_Down", index = 2 },
    { key = "3", kp = "KP_Page_Down", index = 3 },
    { key = "4", kp = "KP_Left", index = 4 },
    { key = "5", kp = "KP_Begin", index = 5 },
    { key = "6", kp = "KP_Right", index = 6 },
    { key = "7", kp = "KP_Home", index = 7 },
    { key = "8", kp = "KP_Up", index = 8 },
    { key = "9", kp = "KP_Page_Up", index = 9 },
}

for _, item in ipairs(num_keys) do
    globalkeys = gears.table.join(
        globalkeys,
        -- Bind both Top Row (#10-18) and Numpad keys
        -- View tag only.
        awful.key({ modkey }, "#" .. item.index + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[item.index]
            if tag then
                tag:view_only()
            end
        end, { description = "view tag #" .. item.index, group = "tag" }),
        awful.key({ modkey }, item.kp, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[item.index]
            if tag then
                tag:view_only()
            end
        end, { description = "view tag #" .. item.index .. " (numpad)", group = "tag" }),

        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. item.index + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[item.index]
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end, { description = "toggle tag #" .. item.index, group = "tag" }),
        awful.key({ modkey, "Control" }, item.kp, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[item.index]
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end, { description = "toggle tag #" .. item.index .. " (numpad)", group = "tag" }),

        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. item.index + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[item.index]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end, { description = "move focused client to tag #" .. item.index, group = "tag" }),
        awful.key({ modkey, "Shift" }, item.kp, function()
            if client.focus then
                local tag = client.focus.screen.tags[item.index]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end, { description = "move focused client to tag #" .. item.index .. " (numpad)", group = "tag" }),

        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. item.index + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[item.index]
                if tag then
                    client.focus:toggle_tag(tag)
                end
            end
        end, { description = "toggle focused client on tag #" .. item.index, group = "tag" }),
        awful.key({ modkey, "Control", "Shift" }, item.kp, function()
            if client.focus then
                local tag = client.focus.screen.tags[item.index]
                if tag then
                    client.focus:toggle_tag(tag)
                end
            end
        end, { description = "toggle focused client on tag #" .. item.index .. " (numpad)", group = "tag" })
    )
end

clientbuttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
    end),
    awful.button({ modkey }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = {},
        properties = {
            border_width = 2,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen,
            size_hints_honor = false,
        },
    },

    -- Floating clients.
    {
        rule_any = {
            instance = {
                "DTA", -- Firefox addon DownThemAll.
                "copyq", -- Includes session name in class.
                "pinentry",
            },
            class = {
                "Arandr",
                "Blueman-manager",
                "Gpick",
                "Kruler",
                "MessageWin", -- kalarm.
                "Sxiv",
                "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
                "Wpa_gui",
                "veromix",
                "xtightvncviewer",
            },

            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name = {
                "Event Tester", -- xev.
            },
            role = {
                "AlarmWindow", -- Thunderbird's calendar.
                "ConfigManager", -- Thunderbird's about:config.
                "pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
            },
        },
        properties = { floating = true },
    },

    -- Add titlebars to normal clients and dialogs
    { rule_any = { type = { "normal", "dialog" } }, properties = { titlebars_enabled = false, ontop = true } },

    -- Set Firefox to always map on the tag named " 1 " on screen 1.
    -- xprop WM_CLASS
    { rule = { class = "Firefox" },
      properties = { screen = 1, tag = " 1 " } },

    { rule = { class = "Geany" },
      properties = { screen = 1, tag = " 2 " } },

    { rule = { class = "Thunar" },
      properties = { screen = 1,
      tag = " 4 ",
      floating = true,
      titlebars_enabled = true,
      placement = awful.placement.no_overlap --need to fix
      },
      callback = function (c)
          awful.placement.centered(c, {honor_workarea = true})
      end
    },

    -- Scratchpads
    {
        rule = { instance = "scratchpad" },
        properties = {
            floating = true,
            ontop = true,
            sticky = true,
            width = 1200,
            height = 700,
        },
        callback = function (c)
            awful.placement.centered(c, {honor_workarea = true})
        end
    },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({}, 1, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({}, 3, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c):setup({
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout = wibox.layout.fixed.horizontal,
        },
        { -- Middle
            { -- Title
                align = "center",
                widget = awful.titlebar.widget.titlewidget(c),
            },
            buttons = buttons,
            layout = wibox.layout.flex.horizontal,
        },
        { -- Right
            awful.titlebar.widget.floatingbutton(c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton(c),
            awful.titlebar.widget.ontopbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal(),
        },
        layout = wibox.layout.align.horizontal,
    })
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)
-- }}}

-- {{{ Autostart applications

-- Run only if not already running
local function run_once(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        awful.spawn.with_shell(string.format("pgrep -u $USER -fx '%s' > /dev/null || (%s &)", cmd, cmd))
    end
end

-- Run every time Awesome reloads
local function run_always(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        awful.spawn.with_shell(cmd)
    end
end

-- Kill if running and start fresh
local function run_restart(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        awful.spawn.with_shell(string.format("pkill -u $USER -fx '%s'; (%s &)", cmd, cmd))
    end
end

-- 1. These only run if they aren't already active
run_once({
    "picom",
    --"nm-applet",
    -- "volumeicon",
})

-- 2. These run EVERY time you press Mod4+Shift+R
run_always({
    "~/.config/awesome/monitor_setup.sh",
    "xset r rate 60 30",
    "xset s 300 300",
    "~/.config/awesome/autostart.sh",

})
-- }}}

--- ░█▀▀░█▀█░█▀▄░█▀▄░█▀█░█▀▀░█▀▀
--- ░█░█░█▀█░█▀▄░█▀▄░█▀█░█░█░█▀▀
--- ░▀▀▀░▀░▀░▀░▀░▀▀░░▀░▀░▀▀▀░▀▀▀

--- Enable for lower memory consumption
collectgarbage("setpause", 110)
collectgarbage("setstepmul", 1000)
gears.timer({
    timeout = 5,
    autostart = true,
    call_now = true,
    callback = function()
        collectgarbage("collect")
    end,
})
