// Glacier layout: a slim top bar and a floating dock on every screen,
// plus the Glacier HUD on each desktop.

var launchers = [
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:google-chrome.desktop",
    "applications:com.anthropic.Claude.desktop",
    "applications:org.prismlauncher.PrismLauncher.desktop",
    "applications:org.kubuntu.manage-software.desktop",
    "applications:systemsettings.desktop"
];

// With no screen attached (headless, over SSH) Plasma reports zero screens:
// the panel loop below would create nothing and screenGeometry() is empty, so
// the old panels would be stripped and the widgets dumped at 0,0. Do nothing.
if (screenCount === 0) {
    print("glacier layout: no screens, leaving the layout alone");
} else {

var old = panels();
for (var i = 0; i < old.length; i++) {
    old[i].remove();
}

for (var s = 0; s < screenCount; s++) {
    var bar = new Panel;
    bar.screen = s;
    bar.location = "top";
    bar.height = Math.round(gridUnit * 1.7);
    bar.floating = false;

    var menu = bar.addWidget("org.kde.plasma.kickoff");
    menu.currentConfigGroup = ["General"];
    menu.writeConfig("icon", "glacier-launcher");
    if (s === 0) {
        menu.currentConfigGroup = ["Shortcuts"];
        menu.writeConfig("global", "Alt+F1");
    }

    bar.addWidget("org.kde.plasma.panelspacer");

    var clock = bar.addWidget("org.kde.plasma.digitalclock");
    clock.currentConfigGroup = ["Appearance"];
    clock.writeConfig("showDate", true);
    clock.writeConfig("dateDisplayFormat", 1); // beside the time
    clock.writeConfig("dateFormat", "custom");
    clock.writeConfig("customDateFormat", "ddd d MMM "); // trailing space: Plasma 6.5 puts no gap before the time
    clock.writeConfig("autoFontAndSize", false);
    clock.writeConfig("fontFamily", "IBM Plex Mono");
    clock.writeConfig("fontSize", 11);
    clock.writeConfig("fontWeight", 500);

    bar.addWidget("org.kde.plasma.panelspacer");
    bar.addWidget("org.kde.plasma.systemtray");

    var dock = new Panel;
    dock.screen = s;
    dock.location = "bottom";
    dock.height = Math.round(gridUnit * 3);
    dock.lengthMode = "fit";
    dock.alignment = "center";
    dock.floating = true;
    dock.hiding = "dodgewindows";

    var tasks = dock.addWidget("org.kde.plasma.icontasks");
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("launchers", launchers.join(","));
    tasks.writeConfig("showOnlyCurrentScreen", true);
}

var hudWidth = 340;
var hudHeight = 330;
var all = desktops();
for (var d = 0; d < all.length; d++) {
    var desk = all[d];
    desk.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desk.writeConfig("Image", "file://" + userDataPath() + "/wallpapers/Glacier");
    desk.wallpaperPlugin = "com.ryan.glacier.live";

    var stale = desk.widgets("com.ryan.glacier.hud");
    for (var w = 0; w < stale.length; w++) {
        stale[w].remove();
    }
    var geo = screenGeometry(desk.screen);
    desk.addWidget("com.ryan.glacier.hud", geo.width - hudWidth - 48, 72, hudWidth, hudHeight);

    stale = desk.widgets("com.ryan.glacier.servers");
    for (w = 0; w < stale.length; w++) {
        stale[w].remove();
    }
    desk.addWidget("com.ryan.glacier.servers", geo.width - hudWidth - 48, 72 + hudHeight + 16, hudWidth, 230);
}

} // screenCount
