{
    description = "nix based image";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/17de0b976395537756f30a3e78f2f06e5cec89ed?narHash=sha256-kOrCcSIA6w9J1hX5DqHy2k9pDTJymExTsbV74U9UtCA=";

    outputs = { nixpkgs, ... }: let
        systemList = [ "x86_64-linux" "aarch64-linux" ];

        mkImageSet = pkgs: let
            inherit (pkgs) lib;

            baseEnv = {
                PATH = "/bin";
                HOME = "/root";
                TZ = "Asia/Shanghai";
                TIME_STYLE = "+%Y-%m-%d %H:%M:%S";
                SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
                NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
            };

            nixConf = pkgs.writeText "nix.conf" ''
                substituters = https://mirrors.cernet.edu.cn/nix-channels/store
                sandbox = false
                filter-syscalls = false
                experimental-features = nix-command flakes
            '';

            baseScript = ''
                mkdir -m 1777 -p tmp
                mkdir -p etc/nix etc/ssl/certs root usr/share
                ln -s ${nixConf} etc/nix/nix.conf
                ln -s ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt etc/ssl/certs/ca-bundle.crt
                ln -s ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt etc/ssl/certs/ca-certificates.crt
                ln -s ${pkgs.tzdata}/share/zoneinfo usr/share/zoneinfo
            '';

            nixEnv = { };

            pythonEnv = {
                PIP_DISABLE_PIP_VERSION_CHECK = "1";
                PIP_INDEX_URL = "https://mirrors.cernet.edu.cn/pypi/simple";
                PYTHONFAULTHANDLER = "1";
                PYTHONDONTWRITEBYTECODE = "1";
            };

            jdkEnv = {
                JAVA_HOME = "/opt/jdk";
                JDK_JAVA_OPTIONS = "--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/jdk.internal.ref=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/sun.nio.cs=ALL-UNNAMED --add-opens=java.base/sun.security.action=ALL-UNNAMED --add-opens=java.base/sun.util.calendar=ALL-UNNAMED --add-opens=java.security.jgss/sun.security.krb5=ALL-UNNAMED";
            };

            goEnv = {
                CGO_ENABLED = "0";
                GO111MODULE = "on";
                GOPROXY = "https://goproxy.cn,direct";
                GOTOOLCHAIN = "local";
            };

            uvEnv = {
                UV_DEFAULT_INDEX = "https://mirrors.cernet.edu.cn/pypi/simple";
                UV_PYTHON_INSTALL_MIRROR = "https://mirrors.cernet.edu.cn/python-build-standalone";
            };

            bunfig = pkgs.writeText "bunfig.toml" ''
                [install]
                linker   = "hoisted"
                lockfile = { save = false }
                registry = { url = "https://registry.npmmirror.com" }
            '';

            bunEnv = { };

            specList = [
                { name = "bashInteractive"; version = "latest"; pkg = pkgs.bashInteractive; base = true; }
                { name = "bzip2"; version = "latest"; pkg = pkgs.bzip2; base = true; }
                { name = "cacert"; version = "latest"; pkg = pkgs.cacert; base = true; }
                { name = "coreutils"; version = "latest"; pkg = pkgs.coreutils; base = true; }
                { name = "curl"; version = "latest"; pkg = pkgs.curl; base = true; }
                { name = "file"; version = "latest"; pkg = pkgs.file; base = true; }
                { name = "findutils"; version = "latest"; pkg = pkgs.findutils; base = true; }
                { name = "gawk"; version = "latest"; pkg = pkgs.gawk; base = true; }
                { name = "git"; version = "latest"; pkg = pkgs.git; base = true; }
                { name = "gnugrep"; version = "latest"; pkg = pkgs.gnugrep; base = true; }
                { name = "gnused"; version = "latest"; pkg = pkgs.gnused; base = true; }
                { name = "gnutar"; version = "latest"; pkg = pkgs.gnutar; base = true; }
                { name = "gzip"; version = "latest"; pkg = pkgs.gzip; base = true; }
                { name = "iproute2"; version = "latest"; pkg = pkgs.iproute2; base = true; }
                { name = "iputils"; version = "latest"; pkg = pkgs.iputils; base = true; }
                { name = "jq"; version = "latest"; pkg = pkgs.jq; base = true; }
                { name = "libstdc++"; version = "latest"; pkg = pkgs.libgcc; base = true; }
                { name = "lsof"; version = "latest"; pkg = pkgs.lsof; base = true; }
                { name = "netcat-openbsd"; version = "latest"; pkg = pkgs.netcat-openbsd; base = true; }
                { name = "openssl"; version = "latest"; pkg = pkgs.openssl; base = true; }
                { name = "patch"; version = "latest"; pkg = pkgs.patch; base = true; }
                { name = "procps"; version = "latest"; pkg = pkgs.procps; base = true; }
                { name = "tzdata"; version = "latest"; pkg = pkgs.tzdata; base = true; }
                { name = "unzip"; version = "latest"; pkg = pkgs.unzip; base = true; }
                { name = "xz"; version = "latest"; pkg = pkgs.xz; base = true; }
                { name = "zip"; version = "latest"; pkg = pkgs.zip; base = true; }
                { name = "nix"; version = "2.35.2"; pkg = pkgs.nixVersions.nix_2_35; env = nixEnv; }
                { name = "python"; version = "3.13"; pkg = pkgs.python313.withPackages (ps: [ ps.pip ps.setuptools ]); env = pythonEnv; }
                { name = "python"; version = "3.14"; pkg = pkgs.python314.withPackages (ps: [ ps.pip ps.setuptools ]); env = pythonEnv; }
                { name = "jdk"; version = "8"; pkg = pkgs.jdk8_headless; env = jdkEnv; script = "mkdir -p opt\nln -s ${pkgs.jdk8_headless.home} opt/jdk\n"; }
                { name = "jdk"; version = "21"; pkg = pkgs.jdk21_headless; env = jdkEnv; script = "mkdir -p opt\nln -s ${pkgs.jdk21_headless.home} opt/jdk\n"; }
                { name = "jdk"; version = "25"; pkg = pkgs.jdk25_headless; env = jdkEnv; script = "mkdir -p opt\nln -s ${pkgs.jdk25_headless.home} opt/jdk\n"; }
                { name = "go"; version = "1.27"; pkg = pkgs.go_1_27; env = goEnv; }
                { name = "uv"; version = "latest"; pkg = pkgs.uv; env = uvEnv; }
                { name = "bun"; version = "latest"; pkg = pkgs.bun; env = bunEnv; script = "mkdir -p root\ninstall -m 644 ${bunfig} root/.bunfig.toml\n"; }
            ];

            stackList = [
                [ "nix" ]
                [ "nix" "go" ]
                [ "nix" "bun" ]
                [ "nix" "python" ]
                [ "nix" "python" "uv" ]
                [ "nix" "jdk" ]
            ];

            normalize = spec: spec // { env = spec.env or { }; pkgList = spec.pkgList or [ spec.pkg ]; script = spec.script or ""; };

            specByName = name: lib.map normalize (lib.filter (spec: spec.name == name) specList);

            mkImage = { name, tag, pkgList, env ? { }, script ? "" }: {
                inherit name tag;
                drv = pkgs.dockerTools.buildLayeredImage {
                    inherit name tag;
                    contents = pkgs.buildEnv {
                        name = "${name}-root";
                        paths = (lib.map (spec: spec.pkg) (lib.filter (spec: spec.base or false) specList)) ++ pkgList;
                        pathsToLink = [ "/bin" ];
                    };
                    extraCommands = baseScript + script;
                    config = {
                        Env = lib.mapAttrsToList (key: value: "${key}=${value}") (baseEnv // env);
                        Cmd = [ "/bin/bash" ];
                        Labels = { "org.opencontainers.image.source" = "https://github.com/openhundun/artifact"; };
                    };
                };
            };

            mkFamily = stack: lib.map (
                combo: mkImage {
                    name = lib.concatStringsSep "-" stack;
                    tag = lib.concatStringsSep "-" (lib.map (name: combo.${name}.version) stack);
                    pkgList = lib.concatMap (name: combo.${name}.pkgList) stack;
                    env = lib.foldl' (acc: name: acc // combo.${name}.env) { } stack;
                    script = lib.concatMapStrings (name: combo.${name}.script) stack;
                }
            ) (lib.cartesianProduct (lib.genAttrs stack specByName));

            imageList = lib.concatMap mkFamily stackList;
        in
        assert lib.asserts.assertMsg (lib.all (stack: lib.all (name: specByName name != [ ]) stack) stackList) "stack references an unknown spec name";
        assert lib.asserts.assertMsg (lib.length (lib.unique (lib.map (spec: "${spec.name}:${spec.version}") specList)) == lib.length specList) "duplicate spec name and version";
        lib.listToAttrs (lib.map (image: lib.nameValuePair "${image.name}:${image.tag}" image.drv) imageList);
    in {
        packages = nixpkgs.lib.genAttrs systemList (system: mkImageSet nixpkgs.legacyPackages.${system});
    };
}
