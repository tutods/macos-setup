# Nix Darwin + Home Manager Multi-Device Setup

This repository manages multiple macOS devices and users using Nix, nix-darwin, Home Manager, and nix-homebrew.

## Structure

```
.
├── flake.nix
├── hosts/
│   └── darwin/
│       ├── personal-mbp.nix
│       └── work-mbp.nix
├── home/
│   ├── tutods/
│   │   └── default.nix
│   └── daniel.a.sousa/
│       └── default.nix
├── modules/
│   └── common.nix (optional)
└── README.md
```

## Usage

- Add device configs in `hosts/darwin/`
- Add user configs in `home/<username>/`
- Shared logic can go in `modules/common.nix`
- Edit `flake.nix` to register new devices/users

## Getting Started

1. Install Nix and nix-darwin
2. Clone this repo
3. Run `darwin-rebuild switch --flake .#<hostname>`

---

See each file for more details. 


````
nix-collect-garbage -d
```