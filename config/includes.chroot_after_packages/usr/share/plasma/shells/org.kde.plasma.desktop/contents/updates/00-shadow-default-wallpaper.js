// Shadow OS: set default desktop wallpaper for Plasma (runs on layout init/update).
// Avoids relying on plasma-org.kde.plasma.desktop-appletsrc in /etc/skel, which
// Plasma may regenerate with new activity/containment IDs on first boot.

(function () {
  var image = "file:///usr/share/wallpapers/shadow/Firewatch.jpg";
  var slidePaths = "/usr/share/wallpapers/shadow";

  var all = desktops();
  for (var i = 0; i < all.length; ++i) {
    var d = all[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");
    d.writeConfig("Image", image);
    d.writeConfig("PreviewImage", image);
    d.writeConfig("SlidePaths", slidePaths);
    d.writeConfig("SlideshowMode", 0);
  }
})();
