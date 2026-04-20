{
  inputs = {
    # Base package set — unstable channel for latest packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Hardware-specific tweaks for Apple MacBook Air 6
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Add Linear for Linux port
    linear-linux.url = "github:selimaj-dev/linear-linux";

    # Manage user-level config (dotfiles, programs, services) declaratively
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # use same nixpkgs as system
    };

    # Nix User Repository — community packages like firefox extensions
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Custom audio packages (SoundThread + CDP, etc.) maintained locally
    audio-pkgs.url = "path:/etc/nixos/audio-pkgs";

    # Private home-manager config (emails, real names) — kept outside this repo
    nixos-private.url = "path:/home/cron/.config/nixos-private";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixos-hardware,
      home-manager,
      nur,
      linear-linux,
      audio-pkgs,
      nixos-private,
      ...
    }:
    {
      nixosConfigurations.BIGSTRONGBOSS = nixpkgs.lib.nixosSystem {
        modules = [
          # Set system arch
          { nixpkgs.hostPlatform = "x86_64-linux"; }

          # Tag each generation with its git commit
          { system.nixos.tags = [ (self.shortRev or self.dirtyShortRev or "unknown") ]; }

          # System hardware scan results (auto-generated)
          ./hardware-configuration.nix

          # Main system configuration
          ./configuration.nix

          # MacBook Air 6 hardware support (wifi, trackpad, etc.)
          nixos-hardware.nixosModules.apple-macbook-air-6

          # Make NUR packages available as pkgs.nur.*
          { nixpkgs.overlays = [ nur.overlays.default ]; }

          # Make audio-pkgs available as pkgs.soundthread, etc.
          { nixpkgs.overlays = [ audio-pkgs.overlays.default ]; }

          # Wire home-manager into the NixOS rebuild cycle
          home-manager.nixosModules.home-manager
          {
            # Use the same pkgs as the system instead of a separate instance
            home-manager.useGlobalPkgs = true;
            # Install user packages to /etc/profiles instead of ~/.nix-profile
            home-manager.useUserPackages = true;
            # User-level config lives in its own file
            home-manager.users.cron = import ./home.nix;
            # Pass through inputs to home manager
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
}
