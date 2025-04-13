{
  pkgs,
  area51,
  externalHostname ? "localhost",
  version ? "dirty",
}:
let

  PORT = toString 4000;
  DATABASE_VOLUME = "/data";
  DATABASE_PATH = "${DATABASE_VOLUME}/area51.sqlite";

  entrypoint = pkgs.writeScript "entrypoint" ''
    #!${pkgs.runtimeShell}

    if [ ! -f "${DATABASE_PATH}" ]; then
        echo "Initializing new SQLite database at ${DATABASE_PATH}"
        ${pkgs.sqlite}/bin/sqlite3 "${DATABASE_PATH}" "VACUUM;"
    else
        echo "SQLite database already exists at ${DATABASE_PATH}"
    fi

    if [ -z "''${RELEASE_COOKIE}" ]; then
      echo "RELEASE_COOKIE is not set, generating a random release cookie"
      export RELEASE_COOKIE=$(dd if=/dev/urandom bs=1 count=16 | hexdump -e '16/1 "%02x"')
    fi

    if [ -z "''${SECRET_KEY_BASE}" ]; then
      echo "SECRET_KEY_BASE is not set, generating a random key"
      export SECRET_KEY_BASE=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | sha256sum | cut -d' ' -f1)
    fi

    ${area51}/bin/area51 "$@"
  '';

in
pkgs.dockerTools.buildLayeredImage {
  name = "area51-umbrella";
  tag = version;
  contents = [
    area51
    pkgs.busybox
    pkgs.openssh
    pkgs.cacert
  ];
  config = {
    Cmd = [ "start" ];
    Entrypoint = [ "${entrypoint}" ];
    Env = [
      "DATABASE_PATH=${DATABASE_PATH}"
      "PORT=${PORT}"
      "EXTERNAL_HOSTNAME=${externalHostname}"
      "TZ=UTC"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "LANG=en_US.UTF-8"
      "LC_ALL=en_US.UTF-8"
    ];
  };
}
