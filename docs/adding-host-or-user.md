# Adding a New Host or User

## New host (machine)

### 1. Copy an existing host

```bash
cp -r hosts/darwin/macbook hosts/darwin/new-machine
```

### 2. Update `hosts/darwin/new-machine/default.nix`

```nix
{ mkHost, mkUser, ... }:

{
  imports = [
    ./dock.nix
    ./homebrew
    (mkHost {
      username   = "newuser";
      hostname   = "new-machine";
      brewUser   = "newuser";
      homeConfig = mkUser {
        username = "newuser";
        role     = "personal"; # or "work"
      };
    })
  ];
}
```

### 3. (Optional) Add role-specific overrides

If the new user needs overrides beyond the shared `home/common/` config, create or edit a role file in `home/roles/`. Otherwise, `mkUser` with `role = "personal"` or `"work"` is sufficient — no per-user directory needed.

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

### 1. Add a role (if needed)

If the new user needs overrides beyond `home/common/`, create a role file `home/roles/<role>.nix`. Otherwise, use an existing role (`personal` or `work`).

In the host's `default.nix`, use `mkUser`:

```nix
homeConfig = mkUser {
  username = "newuser";
  role     = "personal"; # or "work", or a new role name
};
```

`mkUser` (defined in `lib/mkUser.nix`) handles `home.username`, `home.homeDirectory`, and imports — no per-user directory needed unless you have identity-specific overrides.

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
  homeConfig = mkUser {
    username = "normal.user";
    role     = "work";
  };
}
```

Run `./nix.sh <hostname>` from the admin account. Home Manager config is still applied to `normal.user`.
