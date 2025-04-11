{
  description = "Project 51 flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        unstable-packages = final: _prev: {
          unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        };

        elixir_with_gleam =
          final: prev:
          let
            elixir-dev = prev.unstable.elixir.overrideAttrs (old: {
              version = "1.18.1";
              src = prev.fetchFromGitHub {
                owner = "Papipo";
                repo = "elixir";
                rev = "b64f23a35caa321cc942815d0e47298449a72404";
                hash = "sha256-LHqMXmUMfjCZfRnKYl8H0DyvnaTB/t0LYvCnIfHeip4=";
                # rev = "70861671270bf3a999cd506041adb87a2f69b87a";
                # hash = "sha256-zreJ+gqDo8nvwyAqcelT1ADuAMUnOgJqey826n/XU58=";
              };
            });
            elixir-ls-dev = prev.unstable.elixir-ls.override (old: {
              mixRelease =
                args:
                old.mixRelease (
                  args
                  // {
                    elixir = elixir-dev;
                  }
                );
            });
            lexical-dev = prev.unstable.lexical.override (old: {
              elixir = elixir-dev;
              beamPackages = old.beamPackages // {
                mixRelease =
                  args:
                  old.beamPackages.mixRelease (
                    args
                    // {
                      elixir = elixir-dev;
                    }
                  );
              };
            });
            next-ls-dev = prev.unstable.next-ls.override (old: {
              beamPackages = old.beamPackages // {
                mixRelease =
                  args:
                  old.beamPackages.mixRelease (
                    args
                    // {
                      elixir = elixir-dev;
                    }
                  );
              };
            });
          in
          {
            inherit
              elixir-dev
              elixir-ls-dev
              lexical-dev
              next-ls-dev
              ;
          };

        gleam_latest_ol = final: prev: {
          gleam-dev = prev.unstable.gleam.override (old: {
            rustPlatform = old.rustPlatform // {
              buildRustPackage =
                args:
                old.rustPlatform.buildRustPackage (
                  args
                  // {
                    version = "1.10.0";
                    src = prev.fetchFromGitHub {
                      owner = "gleam-lang";
                      repo = "gleam";
                      rev = "cbd6c1793196a0e7ea67c57b62fa51b65116d4d5";
                      hash = "sha256-6ozX+TU07Y6UINsfQ3vmvV/NPfj7W6Nx6aF1RrePWqA=";
                    };
                    cargoHash = "sha256-1jZmqLXGAWnAWlFhOV40Lfqwapa/pX/jLFXeKFcxxkQ=";
                  }
                );
            };
          });
        };

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            unstable-packages
            elixir_with_gleam
            gleam_latest_ol
          ];
        };

        isDarwin = builtins.match ".*-darwin" pkgs.stdenv.hostPlatform.system != null;

        shell = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              gleam-dev
              elixir-dev
              elixir-ls-dev
              # lexical-dev
              # next-ls-dev
              # unstable.gleam
              # unstable.elixir
              # unstable.elixir-ls
              # unstable.lexical
              # unstable.next-ls
              unstable.erlang
              rebar3
              nodejs_22
            ]
            ++ (
              if isDarwin then
                [
                  darwin.apple_sdk.frameworks.Security
                  darwin.apple_sdk.frameworks.Foundation
                ]
              else
                [ ]
            );
          shellHook = ''
            echo "👽👾👽👾👽👾👽👾👽👾👽👾"
          '';
        };

        service_names = [ "area51" ];
        architectures = [
          "amd64"
          "arm64"
        ];

        containers =
          let
            os = "linux";
            all =
              pkgs.lib.mapCartesianProduct
                (
                  {
                    arch,
                    service_name,
                  }:
                  {
                    "${service_name}" = {
                      "${toString arch}" =
                        let
                          nix_arch = builtins.replaceStrings [ "arm64" "amd64" ] [ "aarch64" "x86_64" ] arch;

                          container_pkgs = import nixpkgs {
                            system = "${nix_arch}-${os}";
                            overlays = [
                              unstable-packages
                              elixir_with_gleam
                              gleam_latest_ol
                            ];
                          };

                          service = container_pkgs.callPackage ./release {
                            erlang = container_pkgs.unstable.erlang;
                            nodejs = container_pkgs.nodejs_22;
                            elixir = container_pkgs.elixir-dev;
                            gleam = container_pkgs.gleam-dev;
                          };
                        in
                        container_pkgs.callPackage ./release/docker.nix {
                          area51 = service;
                          pkgs = container_pkgs;
                        };
                    };
                  }
                )
                {
                  arch = architectures;
                  service_name = service_names;
                };
          in
          pkgs.lib.foldl' (set: acc: pkgs.lib.recursiveUpdate acc set) { } all;
      in
      {
        devShells.default = shell;

        packages.image = containers;

        packages.default = pkgs.callPackage ./release {
          erlang = pkgs.unstable.erlang;
          nodejs = pkgs.nodejs_22;
          elixir = pkgs.elixir-dev;
          gleam = pkgs.gleam-dev;
        };
      }
    );
}
