{
  description = "Custom audio software packages";

  inputs = {
    # Base package set — follow same channel as system flake
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # SoundThread: node-based GUI for the Composers Desktop Project
    # Outer tarball bundles CDP as a nested cdprogs_linux.tar.gz which
    # we extract during build, then run via FHS since the binaries
    # aren't built against Nix paths
    soundthread-src = {
      url = "https://github.com/j-p-higgins/SoundThread/releases/download/v0.4.0-beta/SoundThread_v0-4-0-beta_linux_x86_64.tar.gz";
      flake = false; # plain source archive, not a flake
    };

    # Add more audio sources below, e.g.:
    # some-tool-src = { url = "..."; flake = false; };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Stage 1: unpack SoundThread + nested CDP binaries into the store
      soundthread-unwrapped = pkgs.stdenv.mkDerivation {
        pname = "soundthread-unwrapped";
        version = "0.4.0-beta";
        src = inputs.soundthread-src;

        # No compile step — pre-built binaries
        dontBuild = true;
        # Don't strip Godot/CDP binaries — can break signatures/resources
        dontStrip = true;

        installPhase = ''
          runHook preInstall
          mkdir -p $out/opt/soundthread
          cp -r . $out/opt/soundthread/
          # Extract the bundled CDP programs next to the GUI
          tar -xzf $out/opt/soundthread/cdprogs_linux.tar.gz \
            -C $out/opt/soundthread/
          rm $out/opt/soundthread/cdprogs_linux.tar.gz
          chmod +x $out/opt/soundthread/SoundThread.x86_64
          runHook postInstall
        '';
      };
    in
    {
      packages.${system} = {
        # Stage 2: FHS sandbox wrapper so Godot + CDP binaries find libs
        soundthread = pkgs.buildFHSEnv {
          name = "soundthread";

          # Runtime libs needed by the Godot app + CDP CLI tools
          targetPkgs =
            p: with p; [
              libGL
              libX11
              libXext
              libXcursor
              libXinerama
              libXrandr
              libXi
              libxkbcommon
              wayland
              alsa-lib
              pulseaudio
              fontconfig
              freetype
              dbus
              zlib
              glibc
              gcc-unwrapped.lib
            ];

          runScript = "${soundthread-unwrapped}/opt/soundthread/SoundThread.x86_64";
        };
      };

      # Expose packages as an overlay so the system flake can
      # consume them as pkgs.soundthread, etc.
      overlays.default = final: prev: {
        inherit (self.packages.${system}) soundthread;
      };
    };
}
