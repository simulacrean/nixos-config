# nixos-config

Personal NixOS + home-manager config, flake-based. Target: MacBook Air 6 (Haswell).

## Layout

- `configuration.nix` — system config (boot, hardware, networking, audio, keyd)
- `home.nix` — home-manager user config (shell, apps, email, services)
- `audio-pkgs/` — local flake for audio packages (SoundThread, CDP)

## Rebuild

```
nix-switch
```

Defined as a zsh function in `home.nix`; runs `nixos-rebuild switch` and auto-commits + pushes `/etc/nixos` on success.

Or manually:

```
sudo nixos-rebuild switch --flake /etc/nixos#BIGSTRONGBOSS
```

## Private data

Personal data (email accounts, real names) lives in a separate `path:` flake input at `~/.config/nixos-private/` and is intentionally not tracked here. To build this config, either populate that directory with your own data or stub it out:

**`~/.config/nixos-private/flake.nix`:**

```nix
{ outputs = _: { homeModule = ./home.nix; }; }
```

**`~/.config/nixos-private/home.nix`:**

```nix
{ ... }: { }
```

## Pre-commit

```
pre-commit install
```

Wires up `gitleaks` via `.pre-commit-config.yaml` to catch secret leaks before they land.
