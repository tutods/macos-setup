# Nix Darwin + Home Manager Setup

This repository manages multiple macOS devices and users using Nix, [nix-darwin](https://github.com/LnL7/nix-darwin), [Home Manager](https://github.com/nix-community/home-manager), and [nix-homebrew](https://github.com/zhaofengli/nix-homebrew).

## 🚀 Prerequisites

Before you begin, ensure you have the following installed on your Mac:

1.  **Nix (Multi-user installation recommended)**:
    ```bash
    sh <(curl -L https://nixos.org/nix/install)
    ```
2.  **Xcode Command Line Tools**:
    ```bash
    xcode-select --install
    ```

## 🛠️ Installation

1.  **Clone this repository**:
    ```bash
    git clone https://github.com/tutods/macos-setup.git ~/.dotfiles
    cd ~/.dotfiles
    ```


2.  **Install nix-darwin**:
    ```bash
    ./nix.sh <hostname>
    ```
    *Replace `<hostname>` with `macbook` or `work` depending on your device.*

## 📖 Usage

The `nix.sh` script is the main entry point for managing your configuration.

> **IMPORTANT!**
>
> The `nix.sh` script requires Nix to be installed on your system. If you haven't installed it yet, please follow the [Prerequisites](#-prerequisites) section first. If you run the script without Nix, your shell will return a `command not found` error for `nix`.

### Deployment


To build and apply your configuration:
```bash
./nix.sh <hostname>
```

### Options

- `--build-only`: Build the configuration without applying it.
- `--force`: Force a rebuild even if no changes are detected.
- `--help`: Show usage information.

### Examples

```bash
# Update personal MacBook
./nix.sh macbook

# Update work laptop
./nix.sh work

# Just test the build
./nix.sh macbook --build-only
```

## 📂 Structure

```
.
├── flake.nix             # Main flake configuration
├── hosts/                # Host-specific configurations
│   └── darwin/
│       ├── macbook/      # Personal MacBook config
│       └── work/         # Work laptop config
├── home/                 # Home Manager user configurations
│   ├── tutods/
│   └── ...
├── modules/              # Shared Nix modules
│   ├── common.nix        # Common logic for all systems
│   └── darwin/           # Darwin-specific modules (security, networking, etc.)
└── nix.sh                # Helper script for management
```

## 🔧 Customization

### Adding a New Device

1.  **Create host configuration**:
    Create a new directory in `hosts/darwin/<hostname>` and add a `default.nix`. You can copy an existing one as a template.
    ```bash
    cp -r hosts/darwin/macbook hosts/darwin/new-device
    ```
2.  **Register in flake**:
    Open `flake.nix` and add your new device to `darwinConfigurations`:
    ```nix
    "new-device" = mkDarwin "./hosts/darwin/new-device";
    ```
3.  **Apply**:
    Run `./nix.sh new-device` to apply the configuration.

### Adding a New User

1.  **Create user home configuration**:
    Create a new directory in `home/<username>` and add a `default.nix`.
    ```bash
    mkdir -p home/newuser
    touch home/newuser/default.nix
    ```
2.  **Import in host configuration**:
    In your host's `default.nix` (e.g., `hosts/darwin/work/default.nix`), import the new user's home configuration:
    ```nix
    home-manager.users.newuser = import ../../../home/newuser/default.nix;
    ```
3.  **Configure primary user (optional)**:
    Update `system.primaryUser` and `users.users.<username>` in the host configuration if needed.

---

## 🧹 Maintenance

Clean up old generations to free up disk space:
```bash
nix-collect-garbage -d
```