{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  pandoc,
  python3,
  alsa-lib,
  avahi,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rtpmidid";
  version = "26.01";

  src = fetchFromGitHub {
    owner = "davidmoreno";
    repo = "rtpmidid";
    tag = "v${finalAttrs.version}";
    hash = "sha256-+s2IpkuhWvGj1KOBQJHs7hS9HWx6oXyVWSaaLtBoahQ=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    pandoc
  ];

  buildInputs = [
    alsa-lib
    avahi
    # rtpmidid-cli is a plain Python script; patchShebangs rewrites its interpreter
    python3
  ];

  # Upstream derives the version from `git describe`; no .git in the tarball
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'COMMAND bash -c "git describe --match \"v[0-9]*\" --tags --abbrev=5 HEAD | sed '"'"'s/^v//g'"'"' | sed '"'"'s/-/~/g'"'"' | tr -d '"'"'\n'"'"'"' \
                     'COMMAND echo -n "${finalAttrs.version}"'
  '';

  cmakeFlags = [
    (lib.cmakeBool "ENABLE_TESTS" false)
    (lib.cmakeBool "ENABLE_PCH" false)
    (lib.cmakeFeature "LDD" "system")
  ];

  # Upstream ships no CMake install rules — the Makefile copies by hand
  installPhase = ''
    runHook preInstall

    install -Dm755 src/rtpmidid -t $out/bin
    install -Dm755 ../cli/rtpmidid-cli.py $out/bin/rtpmidid-cli
    install -Dm644 ../default.ini -t $out/share/rtpmidid

    pandoc ../rtpmidid.1.md -s -t man -o rtpmidid.1
    pandoc ../rtpmidid-cli.1.md -s -t man -o rtpmidid-cli.1
    install -Dm644 rtpmidid.1 rtpmidid-cli.1 -t $out/share/man/man1

    runHook postInstall
  '';

  meta = {
    description = "RTP MIDI (AppleMIDI) daemon bridging network MIDI to ALSA sequencer";
    homepage = "https://github.com/davidmoreno/rtpmidid";
    license = with lib.licenses; [
      gpl3Plus
      lgpl21Plus
    ];
    mainProgram = "rtpmidid";
    platforms = lib.platforms.linux;
  };
})
