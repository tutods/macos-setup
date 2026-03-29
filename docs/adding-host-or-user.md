# Adding a New Host or User

## New host (machine)

### 1. Copy an existing host

```bash
cp -r hosts/darwin/macbook hosts/darwin/new-machine
```

### 2. Update `hosts/darwin/new-machine/default.nix`

```nix
{ mkHost, ... }:

{
  imports = [
    ./dock.nix
    ./homebrew
    (mkHost {
      username   = "newuser";
      hostname   = "new-machine";
      brewUser   = "newuser";      # use a different value if an admin owns Homebrew
      homeConfig = import ../../../home/newuser/default.nix;
    })
  ];
}
```

### 3. Create a home config

```bash
cp -r home/tutods home/newuser
```

Edit `home/newuser/default.nix` — set the correct `username` and `homeDirectory`.

### 4. Register in `flake.nix`

```nix
darwinConfigurations = {
  "macbook"     = mkDarwin "./hosts/darwin/macbook";
  "work"        = mkDarwin "./hosts/darwin/work";
  "new-machine" = mkDarwin "./hosts/darwin/new-machine";  # add this
};
```

### 5. Deploy

```bash
./nix.sh new-machine
```

### 6. Set up private git identity on the machine

```bash
mkdir -p ~/.config/git
cat > ~/.config/git/private << 'EOF'
[user]
    name  = Your Name
    email = your@email.com
EOF
```

---

## New user on an existing host

### 1. Create the home config

```bash
mkdir -p home/newuser
```

Create `home/newuser/default.nix`:

```nix
{ lib, ... }:

{
  home.username      = "newuser";
  home.homeDirectory = lib.mkForce "/Users/newuser";
  home.stateVersion  = "23.11";

  imports = [ ../programs ];
}
```

`../programs` already imports the shared git config (`home/programs/cli/git.nix`), so no per-user git file is needed.

### 2. Update the host's `default.nix`

Change `mkHost.username` and `mkHost.homeConfig` to point to the new user.

---

## Admin-owned Homebrew (work machines)

If an admin account owns Homebrew but a separate normal user should get the Home Manager config:

```nix
mkHost {
  username   = "normal.user";
  hostname   = "machine-name";
  brewUser   = "admin.user";     # owns /opt/homebrew
  homeConfig = import ../../../home/normal.user/default.nix;
}
```

Run `./nix.sh <hostname>` from the admin account. Home Manager config is still applied to `normal.user`.
