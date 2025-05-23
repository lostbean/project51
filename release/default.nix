{
  pkgs,
  erlang,
  elixir,
  gleam,
  nodejs,
  version ? "dirty",
  ...
}:
let
  pname = "area51";
  inherit version;
  src = ../.;
  mixEnv = "prod";

  beamPkgs = with pkgs; with beam_minimal; packagesWith erlang;

  fetchMixDeps = beamPkgs.fetchMixDeps.override { inherit elixir; };
  mixRelease = beamPkgs.mixRelease.override { inherit elixir erlang fetchMixDeps; };

  MIX_ESBUILD_PATH = "${pkgs.esbuild}/bin/esbuild";

  mixFodDeps = fetchMixDeps {
    pname = "${pname}-deps";
    inherit MIX_ESBUILD_PATH;
    inherit src version mixEnv;
    nativeBuildInputs = [ gleam ];
    preInstall = ''
      export PATH=$PATH:${gleam}/bin
    '';
    hash = "sha256-lWcOrp1TP10XHo7XLspCxTrbAUlXPNHOl8fOJWHgFFg=";
  };

  nodeDeps = pkgs.buildNpmPackage {
    name = "${pname}-node-assets";
    src = ../assets;
    npmDepsHash = "sha256-IOPrxVLgVKdKOLuDeNhx5ad1RNhAPRXQQwk5PIbSNmE=";
    dontNpmBuild = true;
    inherit nodejs;

    installPhase = ''
      mkdir $out
      cp -r node_modules $out
      ln -s $out/node_modules/.bin $out/bin
    '';
  };

  injected_envars = import ./inject_envars.nix;

in
mixRelease {
  inherit
    pname
    version
    src
    mixEnv
    mixFodDeps
    ;
  inherit MIX_ESBUILD_PATH;

  APP_AUTH0_AUDIENCE = "https://${injected_envars.APP_AUTH0_DOMAIN}/api/v2/";
  APP_AUTH0_JWKS_URL = "https://${injected_envars.APP_AUTH0_DOMAIN}/.well-known/jwks.json";
  APP_AUTH0_DOMAIN = injected_envars.APP_AUTH0_DOMAIN;
  APP_AUTH0_CLIENT_ID = injected_envars.APP_AUTH0_CLIENT_ID;
  APP_AUTH0_CALLBACK_URL = injected_envars.APP_AUTH0_CALLBACK_URL;

  EXTERNAL_DOMAIN = injected_envars.EXTERNAL_DOMAIN;
  EXTERNAL_PORT = injected_envars.EXTERNAL_PORT;

  OTLP_ENDPOINT = injected_envars.OTLP_ENDPOINT;
  GRAFANA_URL = injected_envars.GRAFANA_URL;

  nativeBuildInputs = [
    nodejs
    gleam
    pkgs.esbuild
    pkgs.yarn
  ];

  preConfigure = ''
    export ELIXIR_MAKE_CACHE_DIR="$TMPDIR/cache"
    export PATH=$PATH:${gleam}/bin
    export HOME=$TMPDIR
  '';

  preBuild = ''
    export HOME=$TMPDIR
    chmod -R +w priv/static/
    ln -sf ${nodeDeps}/node_modules assets/node_modules
    mix assets.deploy
  '';

  installPhase = ''
    mkdir -p $out
    mix release --no-deps-check --path "$out"
  '';
}
