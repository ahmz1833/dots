// Plasma layout applied by dots/kde (DOTS_KDE_LAYOUT). settings.sh replaces
// @CONFIG@ with a JSON object built from kde/config.sh.
var cfg = @CONFIG@;

panels().forEach(function (p) { p.remove(); });

var panel = new Panel("org.kde.panel");
panel.location = "bottom";
panel.height = cfg.height;
panel.hiding = "none";
panel.floating = cfg.floating;

var kickoff = panel.addWidget("org.kde.plasma.kickoff");
if (cfg.launcherIcon) {
    kickoff.currentConfigGroup = ["General"];
    kickoff.writeConfig("icon", cfg.launcherIcon);
}

var tasks = panel.addWidget("org.kde.plasma.icontasks");
if (cfg.launchers.length > 0) {
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("launchers", cfg.launchers);
}

if (knownWidgetTypes.indexOf("org.kde.netspeedWidget") !== -1) {
    var net = panel.addWidget("org.kde.netspeedWidget");
    net.currentConfigGroup = ["General"];
    net.writeConfig("speedUnits", "bits");
    net.writeConfig("swapDownUp", true);
}

panel.addWidget("org.kde.plasma.systemtray");

var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showSeconds", "Always");
clock.writeConfig("dateFormat", "isoDate");
clock.writeConfig("use24hFormat", 2);
clock.writeConfig("firstDayOfWeek", cfg.firstDay);
clock.writeConfig("enabledCalendarPlugins", ["alternatecalendar", "holidaysevents"]);

panel.addWidget("org.kde.plasma.showdesktop");

if (cfg.wallpapers.length > 0) {
    desktops().forEach(function (d) {
        var i = Math.min(Math.max(d.screen, 0), cfg.wallpapers.length - 1);
        d.wallpaperPlugin = "org.kde.slideshow";
        d.currentConfigGroup = ["Wallpaper", "org.kde.slideshow", "General"];
        d.writeConfig("SlidePaths", cfg.wallpapers[i]);
        d.writeConfig("SlideInterval", cfg.interval);
    });
}
