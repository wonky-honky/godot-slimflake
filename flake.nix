{
  description = "A template for Nix based C++ project setup.";

  inputs = {
    # Pointing to the current stable release of nixpkgs. You can
    # customize this to point to an older version or unstable if you
    # like everything shining.
    #
    # E.g.
    #
    # nixpkgs.url = "github:NixOS/nixpkgs/unstable";
    #    rbfx.url = "github:pillowtrucker/rbfx/mine";
    #    nixpkgs-llvm18 = {
    #      type = "github";
    #      owner = "ExpidusOS";
    #      repo = "nixpkgs";
    #      ref = "feat/llvm-18";
    #    };
    fbx2gltf.url = "github:pillowtrucker/FBX2GLTF/mine";
    nixpkgs.url = "github:NixOS/nixpkgs/master";

    utils.url = "github:numtide/flake-utils";

  };

  outputs = { self, nixpkgs, ... }@inputs:
    inputs.utils.lib.eachSystem [
      # Add the system/architecture you would like to support here. Note that not
      # all packages in the official nixpkgs support all platforms.
      "x86_64-linux"
      "i686-linux"
      "aarch64-linux"
      "x86_64-darwin"
    ] (system:
      let

        myClangStdenv = pkgs.stdenvAdapters.useMoldLinker
          (pkgs.stdenvAdapters.overrideCC pkgs.llvmPackages_18.stdenv
            (pkgs.llvmPackages_18.clang.override {
              bintools = pkgs.llvmPackages_18.bintools;
            }));
        pkgs = import nixpkgs {
          inherit system;

          # Add overlays here if you need to override the nixpkgs
          # official packages.
          overlays = [
            (final: prev: {

              llvmPackages = final.llvmPackages_18;
              #                  };
              #              })
              #                llvmPackages_18 clang_18 lld_18 lldb_18 llvm_18 clang-tools_18;
              redis = prev.redis.overrideAttrs { doCheck = false; };
              pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                (python-final: python-prev: {
                  conan = python-prev.dontCheck python-prev.conan;

                })

              ];
              ell = prev.ell.overrideAttrs { doCheck = false; };
            })

          ];

          # Uncomment this if you need unfree software (e.g. cuda) for
          # your project.
          #
          config.allowUnfree = true;
        };
      in {
        devShells.default = myClangStdenv.mkDerivation rec {
          # Update the name to something that suites your project.
          name = "godot_shell";
          stdenv = myClangStdenv;
          #          stdenv = pkgs.llvmPackages_18.libcxxStdenv;
          packages = with pkgs;
            with xorg;
            [
              # Development Tools
              llvmPackages_18.clang-tools
              llvmPackages_18.bintools
              python3
              git
              boost
              fmt_8
              libxml2
              inputs.fbx2gltf.packages.${system}.default

              #              (pkgs.llvmPackages_18.libcxx.override { enableShared = false; })
              pkgs.llvmPackages_18.compiler-rt
              cmake
              cmakeCurses
              ninja
              conan
              # Development time dependencies
              #              gtest
              #            rbfx.packages.${system}.default
              vulkan-validation-layers
              # Build time and Run time dependencies
              vulkan-loader
              vulkan-headers
              vulkan-tools
              pkg-config
              xorg.libX11
              libdrm
              libxkbcommon
              libXext
              libXv
              libXrandr
              libxcb
              zlib
              #            gtk3
              #            libuuid
              wayland
              libpulseaudio
              pulseaudio
              dbus
              dbus.lib
              scons
              speechd
              fontconfig
              fontconfig.lib
              vulkan-loader
              libGL
              scons
              alsa-lib
              #            spdlog
              #            abseil-cpp
            ] ++ [
              libXcursor
              libXinerama
              libXext
              libXrandr
              libXrender
              libXi
              libXfixes
              libxkbcommon
            ];
          buildInputs = packages;
          nativeBuildInputs = packages;
          APPEND_LIBRARY_PATH = with pkgs;
            lib.makeLibraryPath [
              libGL
              mesa
              udev
              fontconfig
              libxkbcommon
              vulkan-loader
              libxkbcommon
              xorg.libXinerama
              xorg.libXext
              xorg.libX11
              xorg.libxcb
              xorg.libXcursor
              xorg.libXi
              xorg.libXrandr
            ];

          shellHook = ''
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$APPEND_LIBRARY_PATH"
          '';

          # Setting up the environment variables you need during
          # development.
          #      shellHook = let
          #        icon = "f121";
          #      in ''
          #        export PS1="$(echo -e '\u${icon}') {\[$(tput sgr0)\]\[\033[38;5;228m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]} (${name}) \\$ \[$(tput sgr0)\]"
          #      '';
        };
        packages.fbx2gltf = inputs.fbx2gltf.packages.${system}.default;
        packages.godot = pkgs.callPackage ./default.nix {
          #          stdenv = pkgs.llvmPackages_18.stdenv;
          withPrecision = "double";
          stdenv = myClangStdenv;
          withDebug = false;
        };
      });
}
