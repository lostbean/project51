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

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            unstable-packages
          ];
        };

        isDarwin = builtins.match ".*-darwin" pkgs.stdenv.hostPlatform.system != null;

        shell = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              unstable.gleam
              unstable.elixir
              unstable.erlang
              unstable.lexical
              # unstable.elixir-ls
              # unstable.next-ls
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
                            ];
                          };

                          service = container_pkgs.callPackage ./release {
                            erlang = container_pkgs.unstable.erlang;
                            elixir = container_pkgs.unstable.elixir;
                            gleam = container_pkgs.unstable.gleam;
                            nodejs = container_pkgs.nodejs_22;
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
