#!/bin/bash

qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var desktops = desktops();
for (var i=0;i<desktops.length;i++) {
  d = desktops[i];
  d.wallpaperPlugin = 'org.kde.image';
  d.currentConfigGroup = Array('Wallpaper','org.kde.image','General');
  d.writeConfig('Image', 'file:///usr/share/wallpapers/shadow/Desert.jpg');
}
"

