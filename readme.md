# Shadow OS Factory

> **Building a modern Debian-based Linux distribution from source using Debian Live Build.**

![Platform](https://img.shields.io/badge/Base-Debian%2013%20(Trixie)-A81D33?logo=debian)
![Desktop](https://img.shields.io/badge/Desktop-KDE%20Plasma-1D99F3?logo=kde)
![Build](https://img.shields.io/badge/Build-live--build-success)
![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## Overview

**Shadow OS** is a custom Debian-based Linux distribution built using the **Debian Live Build** framework. The project explores professional Linux distribution engineering by developing a fully customized operating system rather than simply modifying an existing desktop.

The objective is to build a reproducible, secure, and modern desktop operating system with custom branding, automated builds, deep KDE Plasma customization, boot branding, and security hardening.

---

## Features

### Desktop

- KDE Plasma desktop
- Custom Plasma layout
- Shadow OS wallpapers
- System-wide KDE defaults
- Custom Look-and-Feel package
- Custom desktop branding

### Boot Experience

- Custom Plymouth theme
- Custom GRUB theme
- Branded boot sequence
- Initramfs integration

### Branding

- Custom distribution identity
- Shadow OS logos
- Fastfetch ASCII logo
- Custom machine information
- Release metadata
- Terminal branding

### Security

- AppArmor enabled
- Firewall configured by default
- Hardened system defaults
- Custom sudo policy

### Build System

- Debian Live Build
- Modular package lists
- Automated build scripts
- Build hooks
- Filesystem overlays
- Reproducible ISO generation

---

# Technical Stack

| Component | Technology |
|------------|------------|
| Base Distribution | Debian 13 (Trixie) |
| Build Framework | Debian Live Build |
| Desktop | KDE Plasma |
| Display Manager | SDDM |
| Bootloader | GNU GRUB |
| Boot Splash | Plymouth |
| Init System | systemd |
| Security | AppArmor + UFW |
| Shell | Bash |

---

# Project Structure

```
shadow-os-factory/
│
├── auto/                              # live-build wrapper scripts
│   ├── build
│   ├── clean
│   └── config
│
├── config/
│   ├── archives/                      # Additional repositories
│   ├── bootloaders/                   # GRUB configuration
│   ├── hooks/                         # Build hooks
│   │   └── live/
│   ├── includes.chroot/               # Files copied before packages
│   ├── includes.chroot_after_packages/
│   │   ├── etc/
│   │   ├── lib/
│   │   └── usr/
│   ├── package-lists/                 # Modular package lists
│   └── preseed/                       # Automated installer configs
│
├── build.sh                           # ISO build script
├── README.md
└── LICENSE
```

---

# Repository Layout

## `auto/`

Wrapper scripts used by Debian Live Build for configuring, cleaning, and building the distribution.

---

## `config/hooks/`

Contains automated build-time scripts responsible for:

- Security configuration
- AppArmor setup
- Firewall initialization
- Plymouth registration
- KDE configuration
- GRUB branding
- Initramfs updates

---

## `config/package-lists/`

Modular package definitions grouped by functionality.

Examples include:

- Base system
- Desktop environment
- Utilities
- Development tools
- Drivers
- Networking

---

## `config/includes.chroot/`

Contains files copied directly into the root filesystem during image creation.

---

## `config/includes.chroot_after_packages/`

Contains files installed after package installation to override package defaults.

This includes:

- KDE Plasma configuration
- Plymouth themes
- Wallpapers
- Distribution branding
- Machine metadata
- Live-config components
- System utilities

---

# Branding Assets

Shadow OS stores branding resources following the Linux Filesystem Hierarchy Standard.

```
usr/share/
├── plasma/
│   └── look-and-feel/
├── plymouth/
│   └── themes/
├── shadow/
│   ├── logo.txt
│   ├── shadow.png
│   └── shadow-logo.png
└── wallpapers/
    └── shadow/
```

These assets are shared across multiple components including:

- KDE Plasma
- Plymouth
- Fastfetch
- GRUB
- Login Manager
- Desktop wallpaper

---

# Build Pipeline

```
Source Files
      │
      ▼
Debian Live Build Configuration
      │
      ▼
Package Installation
      │
      ▼
Filesystem Overlays
      │
      ▼
Build Hooks
      │
      ▼
Initramfs Generation
      │
      ▼
GRUB Configuration
      │
      ▼
ISO Packaging
      │
      ▼
Shadow OS ISO
```

---

# Skills Demonstrated

## Linux Engineering

- Linux filesystem hierarchy
- Boot process
- Initramfs
- System services
- Distribution architecture

## Distribution Engineering

- Debian Live Build
- Package management
- Hook systems
- Overlay filesystems
- Release engineering

## Desktop Engineering

- KDE Plasma customization
- Plasma layout scripting
- XDG configuration
- System defaults

## Security

- AppArmor
- Firewall configuration
- Secure system defaults

## Automation

- Bash scripting
- Build automation
- Logging
- Resource management
- Reproducible builds

---

# Building Shadow OS

Clone the repository:

```bash
git clone https://github.com/gt-ayush/shadow-os-factory.git
cd shadow-os-factory
```

Install dependencies:

```bash
sudo apt install live-build git
```

Build the ISO:

```bash
chmod +x build.sh
./build.sh
```

After a successful build, the generated ISO will be available in the project directory.

---

# Roadmap

### Completed

- Debian Live Build integration
- KDE Plasma customization
- Custom desktop layout
- Plymouth branding
- Fastfetch branding
- Security hardening
- Automated build pipeline
- Custom wallpapers
- Distribution branding

### In Progress

- Advanced GRUB customization
- Installer integration
- Performance optimization
- Additional branding improvements

### Planned

- Calamares installer
- Package repository
- OTA update infrastructure
- CI/CD build automation
- ARM64 support
- Multiple desktop variants

---

# Contributing

Contributions are welcome.

If you would like to improve Shadow OS:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

---

# Disclaimer

Shadow OS is an educational and engineering project focused on Linux distribution development. It is under active development and is not yet intended for production use.

---

# Acknowledgements

This project builds upon the work of:

- Debian Project
- Debian Live Build Team
- KDE Community
- GNU Project
- Plymouth Developers
- Linux Kernel Community
- Open Source Contributors worldwide

---

# License

This project is licensed under the **MIT License**.

See the `LICENSE` file for details.

---

## Author

**Ayush**

Student • Linux Enthusiast • Open Source Developer

---

> **Shadow OS** — *Engineering a Linux distribution from the ground up.*