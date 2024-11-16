{ stdenv, lib, pkgs, fetchFromGitHub, pkg-config, autoPatchelfHook
, installShellFiles, scons, vulkan-loader, libGL, libX11, libXcursor
, libXinerama, libXext, libXrandr, libXrender, libXi, libXfixes, libxkbcommon
, alsa-lib, libpulseaudio, dbus, speechd, fontconfig, udev
, withPlatform ? "linuxbsd", withTarget ? "editor", withPrecision ? "single"
, withPulseaudio ? true, withDbus ? true, withSpeechd ? true
, withFontconfig ? true, withUdev ? true, withTouch ? true, withDebug ? true }:

assert lib.asserts.assertOneOf "withPrecision" withPrecision [
  "single"
  "double"
];

let
  mkSconsFlagsFromAttrSet = lib.mapAttrsToList (k: v:
    if builtins.isString v then "${k}=${v}" else "${k}=${builtins.toJSON v}");
in stdenv.mkDerivation rec {
  pname = "godot";
  #  version = "4.2.2-stable";
  version = "enable-collision-handling-with-mouse-captured";
  commitHash = "7b043832572447c0b91e614df58b73830b442958";

  #  src = ./.;
  #  src = fetchFromGitHub {
  #    owner = "godotengine";
  #    repo = "godot";
  #    rev = version;
  #    hash = "sha256-anJgPEeHIW2qIALMfPduBVgbYYyz1PWCmPsZZxS9oHI";
  #  };
  src = fetchFromGitHub {
    owner = "pillowtrucker";
    repo = "godot";
    rev = commitHash;
    hash = "sha256-EIrYwUoqmKtVIuB814no+VHodSsIZfgW3xi1rZ+eS5M=";

  };

  nativeBuildInputs = [
    pkg-config
    autoPatchelfHook
    installShellFiles
    pkgs.llvmPackages_18.clang-tools
    pkgs.llvmPackages_18.bintools

  ];

  buildInputs = [
    scons
    #    (pkgs.llvmPackages_18.libcxx.override { enableShared = false; })
    #    pkgs.llvmPackages_18.libraries.libcxx
    pkgs.llvmPackages_18.compiler-rt
  ];

  runtimeDependencies = [

    vulkan-loader
    libGL
    libX11
    libXcursor
    libXinerama
    libXext
    libXrandr
    libXrender
    libXi
    libXfixes
    libxkbcommon
    alsa-lib
  ] ++ lib.optional withPulseaudio libpulseaudio ++ lib.optional withDbus dbus
    ++ lib.optional withDbus dbus.lib ++ lib.optional withSpeechd speechd
    ++ lib.optional withFontconfig fontconfig
    ++ lib.optional withFontconfig fontconfig.lib ++ lib.optional withUdev udev;

  enableParallelBuilding = true;

  # Set the build name which is part of the version. In official downloads, this
  # is set to 'official'. When not specified explicitly, it is set to
  # 'custom_build'. Other platforms packaging Godot (Gentoo, Arch, Flatpack
  # etc.) usually set this to their name as well.
  #
  # See also 'methods.py' in the Godot repo and 'build' in
  # https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-method-get-version-info
  BUILD_NAME = "nixpkgs";

  # Required for the commit hash to be included in the version number.
  #
  # `methods.py` reads the commit hash from `.git/HEAD` and manually follows
  # refs. Since we just write the hash directly, there is no need to emulate any
  # other parts of the .git directory.
  #
  # See also 'hash' in
  # https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-method-get-version-info
  preConfigure = ''
    mkdir -p .git
    echo ${commitHash} > .git/HEAD
  '';

  sconsFlags = mkSconsFlagsFromAttrSet {
    # Options from 'SConstruct'
    production = true; # Set defaults to build Godot for use in production
    platform = withPlatform;
    target = withTarget;
    precision = withPrecision; # Floating-point precision level
    debug_symbols = withDebug;
    # Options from 'platform/linuxbsd/detect.py'
    pulseaudio = withPulseaudio; # Use PulseAudio
    dbus =
      withDbus; # Use D-Bus to handle screensaver and portal desktop settings
    speechd = withSpeechd; # Use Speech Dispatcher for Text-to-Speech support
    fontconfig = withFontconfig; # Use fontconfig for system fonts support
    udev = withUdev; # Use udev for gamepad connection callbacks
    touch = withTouch; # Enable touch events
    use_llvm = true;
    linker = "mold";
    #    LINK = "ld.lld";
    use_static_cpp = true;
  };
  dontStrip = withDebug;
  outputs = [ "out" "man" ];

  installPhase = ''
    mkdir -p "$out/bin"
    cp bin/godot.* $out/bin/godot4

    installManPage misc/dist/linux/godot.6

    mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
    cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/org.godotengine.Godot4.desktop"
    substituteInPlace "$out/share/applications/org.godotengine.Godot4.desktop" \
      --replace "Exec=godot" "Exec=$out/bin/godot4" \
      --replace "Godot Engine" "Godot Engine 4"
    cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
    cp icon.png "$out/share/icons/godot.png"
  '';

  meta = with lib; {
    homepage = "https://godotengine.org";
    description = "Free and Open Source 2D and 3D game engine";
    license = licenses.mit;
    platforms = [ "i686-linux" "x86_64-linux" "aarch64-linux" ];
    maintainers = with maintainers; [ shiryel ];
    mainProgram = "godot4";
  };
}
