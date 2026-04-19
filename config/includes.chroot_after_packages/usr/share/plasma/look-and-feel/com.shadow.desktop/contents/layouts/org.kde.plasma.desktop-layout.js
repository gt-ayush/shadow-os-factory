// =======================
// DESKTOP
// =======================
var desktops = desktops();
for (i = 0; i < desktops.length; i++) {
    d = desktops[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file:///usr/share/wallpapers/shadow/Fire-Watch.jpg");
}

// =======================
// TOP PANEL
// =======================
var panel1 = new Panel();
panel1.location = "top";
panel1.height = 35;
panel1.lengthMode = "fill";
panel1.floating = false;

// Order EXACT match
panel1.addWidget("org.kde.plasma.trash");

var spacer1 = panel1.addWidget("org.kde.plasma.panelspacer");
spacer1.writeConfig("expanding", true);

panel1.addWidget("org.kde.plasma.digitalclock");

var spacer2 = panel1.addWidget("org.kde.plasma.panelspacer");
spacer2.writeConfig("expanding", true);

panel1.addWidget("org.kde.plasma.marginsseparator");
panel1.addWidget("org.kde.plasma.systemtray");
panel1.addWidget("org.kde.plasma.showdesktop");

// =======================
// RIGHT PANEL (FLOATING)
// =======================
var panel2 = new Panel();
panel2.location = "right";
panel2.height = 400;
panel2.lengthMode = "fit";
panel2.floating = true;
panel2.alignment = "center";
panel2.visibility = "dodgewindows";

// EXACT widgets
panel2.addWidget("org.kde.plasma.kicker");   // apps menu
panel2.addWidget("org.kde.milou");           // search
panel2.addWidget("org.kde.plasma.icontasks");// apps dock
