# Shadow OS

> **A Modern, Performance-Focused, Security-Conscious Debian-Based Linux Distribution**

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Debian-red)
![Desktop](https://img.shields.io/badge/Desktop-KDE%20Plasma-blue)
![Status](https://img.shields.io/badge/Status-Active%20Development-success)

---

## Overview

**Shadow OS** is a custom Debian-based Linux distribution built from the ground up using **Debian Live Build**. The project focuses on creating a polished, reproducible, and production-ready operating system with deep system-level customization rather than simple package or theme modifications.

Shadow OS aims to provide a modern desktop experience while demonstrating advanced Linux distribution engineering concepts, including build automation, desktop integration, system branding, security hardening, and reproducible operating system deployment.

---

## Features

### 🎨 Desktop Experience

- KDE Plasma Desktop
- Custom Shadow OS branding
- Custom wallpapers
- Customized panel layout
- Plasma Look-and-Feel integration
- System-wide KDE configuration
- Custom Fastfetch branding

### 🚀 Boot Experience

- Custom Plymouth boot animation
- Custom GRUB theme
- Boot splash branding
- Customized boot sequence

### 🔒 Security

- AppArmor enabled by default
- Firewall configured out of the box
- Secure sudo configuration
- Security-focused system defaults

### ⚙️ System Engineering

- Debian Live Build architecture
- Modular package lists
- Hook-based automation
- Filesystem overlays
- Reproducible ISO builds
- Automated build pipeline

---

# Project Goals

The primary objective of Shadow OS is to explore and implement professional Linux distribution engineering practices by building a complete operating system that demonstrates:

- Distribution Engineering
- Linux System Architecture
- Desktop Environment Customization
- Boot Process Engineering
- Security Hardening
- Build Automation
- System Branding
- Reproducible Builds

---

# Technical Stack

| Component | Technology |
|------------|------------|
| Base Distribution | Debian 13 (Trixie) / Debian 12 (Bookworm) |
| Build System | Debian Live Build (`live-build`) |
| Desktop Environment | KDE Plasma |
| Display Manager | SDDM |
| Init System | systemd |
| Boot Splash | Plymouth |
| Bootloader | GNU GRUB |
| Security | AppArmor + UFW |
| Shell | Bash |

---

# Project Structure

```text
shadow-os-factory/
│
├── auto/
│   ├── build
│   ├── clean
│   └── config
│
├── config/
│   ├── archives/
│   ├── bootloaders/
│   ├── hooks/
│   ├── includes.chroot/
│   ├── includes.chroot_after_packages/
│   ├── package-lists/
│   └── preseed/
│
├── images/
│
├── scripts/
│
├── build.sh
│
└── README.md
```

---

# Core Features

## Custom Distribution Build System

- Automated ISO generation
- Modular architecture
- Package management
- Build automation
- Hook execution
- Overlay filesystem support

---

## KDE Plasma Customization

- System-wide Plasma configuration
- Custom panel layouts
- Theme customization
- Wallpaper integration
- Default desktop configuration
- Plasma layout scripting

---

## Branding

Shadow OS includes custom branding across multiple components:

- Distribution identity
- Fastfetch logo
- Boot splash
- Login screen
- Wallpapers
- Machine information
- Release information
- Terminal branding

---

## Boot Customization

- Plymouth theme
- GRUB theme
- Initramfs integration
- Boot asset deployment

---

## Security

- AppArmor enabled
- Firewall configuration
- Secure defaults
- Hardened desktop environment

---

# Build Requirements

- Debian 12 (Bookworm) or Debian 13 (Trixie)
- live-build
- Git
- Bash
- Root privileges (for build operations)
- 16 GB RAM recommended
- 30+ GB free disk space

---

# Building Shadow OS

Clone the repository:

```bash
git clone https://github.com/<your-username>/shadow-os.git
cd shadow-os
```

Install dependencies:

```bash
sudo apt install live-build git
```

Build the ISO:

```bash
./build.sh
```

The generated ISO will be available after a successful build.

---

# Skills Demonstrated

This project showcases practical experience in:

### Linux

- Linux Internals
- Filesystem Hierarchy
- Initramfs
- Boot Process
- System Services

### Distribution Engineering

- Debian Live Build
- Package Management
- Hook Systems
- Filesystem Overlays
- Release Engineering

### Desktop Engineering

- KDE Plasma
- XDG Configuration
- Plasma Layout Scripts
- System Defaults

### DevOps

- Bash Automation
- Build Pipelines
- Logging
- Reproducible Builds

### Security

- AppArmor
- Firewall Configuration
- Linux Hardening

---

# Roadmap

## Completed

- Debian Live Build integration
- KDE Plasma customization
- Plymouth branding
- Fastfetch branding
- Security hardening
- Wallpaper integration
- Build automation
- System branding

## In Progress

- Custom GRUB theme
- Installer customization
- Branding improvements
- Performance optimization

## Planned

- Calamares installer integration
- Package repository
- Automatic updates
- Release management
- CI/CD build pipeline
- Multi-desktop variants
- ARM64 support

---

# Contributing

Contributions, bug reports, feature requests, and suggestions are welcome.

If you would like to contribute:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Submit a Pull Request

---

# Disclaimer

Shadow OS is currently an educational and research project intended to explore Linux distribution engineering, operating system customization, and automation techniques.

It is under active development and should not yet be considered production-ready.

---

# Author

**Ayush**

Student • Linux Enthusiast • Open Source Developer

---

# Acknowledgements

This project builds upon the incredible work of:

- Debian Project
- Debian Live Build Team
- KDE Community
- Plymouth Developers
- GNU Project
- Linux Kernel Community
- Open Source Contributors worldwide

---

## License

This project is released under the **MIT License**.

See the `LICENSE` file for more information.

---

> **Shadow OS** — *Engineering a Linux distribution from the ground up.*