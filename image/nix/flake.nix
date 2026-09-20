{
    description = "nix 组合镜像";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/17de0b976395537756f30a3e78f2f06e5cec89ed?narHash=sha256-kOrCcSIA6w9J1hX5DqHy2k9pDTJymExTsbV74U9UtCA=";

    outputs =
        { nixpkgs, ... }:
        let
            nixVersionList = [ "2_35" ];
            pythonVersionList = [
                "313"
                "314"
            ];
            jdkVersionList = [
                "8"
                "17"
                "21"
                "25"
            ];
            goVersionList = [ "1_27" ];
            llvmVersionList = [ "21" ];
            zigVersionList = [ "0_16" ];
            uvVersionList = [ "latest" ];
            bunVersionList = [ "latest" ];

            systems = [
                "x86_64-linux"
                "aarch64-linux"
            ];

            mkImages =
                pkgs:
                let
                    inherit (pkgs) lib;

                    axes = {
                        nix = {
                            list = nixVersionList;
                            pkg = version: pkgs.nixVersions."nix_${version}";
                            tag = version: pkg: pkg.version;
                        };

                        python = {
                            list = pythonVersionList;
                            pkg =
                                version:
                                pkgs."python${version}".withPackages (ps: [
                                    ps.pip
                                    ps.setuptools
                                ]);
                            tag = version: pkg: lib.versions.majorMinor pkgs."python${version}".version;
                            env = version: pkg: {
                                PIP_DISABLE_PIP_VERSION_CHECK = "1";
                                PIP_INDEX_URL = "https://mirrors.ustc.edu.cn/pypi/simple";
                                PYTHONFAULTHANDLER = "1";
                                PYTHONDONTWRITEBYTECODE = "1";
                            };
                        };

                        jdk = {
                            list = jdkVersionList;
                            pkg = version: pkgs."jdk${version}_headless";
                            tag = version: pkg: version;
                            env = version: pkg: {
                                JAVA_HOME = "/opt/jdk";
                            };
                            extraCommands = version: pkg: ''
                                mkdir -p opt
                                ln -s ${pkg.home} opt/jdk
                            '';
                        };

                        go = {
                            list = goVersionList;
                            pkg = version: pkgs."go_${version}";
                            tag = version: pkg: lib.versions.majorMinor pkg.version;
                            env = version: pkg: {
                                GOPROXY = "https://goproxy.cn,direct";
                                GOTOOLCHAIN = "local";
                                CGO_ENABLED = "0";
                            };
                        };

                        llvm = {
                            list = llvmVersionList;
                            pkg = version: pkgs."llvmPackages_${version}".llvm;
                            tag = version: pkg: lib.versions.major pkg.version;
                            paths = version: pkg: [
                                pkgs."llvmPackages_${version}".clang
                                pkgs."llvmPackages_${version}".lld
                                pkgs."llvmPackages_${version}".llvm
                                pkgs."llvmPackages_${version}".llvm.dev
                                pkgs.ccache
                                pkgs.cmake
                                pkgs.gnumake
                                pkgs.ninja
                                pkgs.pkg-config
                            ];
                        };

                        zig = {
                            list = zigVersionList;
                            pkg = version: pkgs."zig_${version}";
                            tag = version: pkg: lib.versions.majorMinor pkg.version;
                        };

                        uv = {
                            list = uvVersionList;
                            pkg = version: pkgs.uv;
                            tag = version: pkg: version;
                            env = version: pkg: {
                                UV_DEFAULT_INDEX = "https://mirrors.ustc.edu.cn/pypi/simple";
                            };
                        };

                        bun = {
                            list = bunVersionList;
                            pkg = version: pkgs.bun;
                            tag = version: pkg: version;
                        };
                    };

                    # 一个轴的全部取值：version / pkg / tag
                    axisValues =
                        name:
                        let
                            axis = axes.${name};
                        in
                        map (
                            version:
                            let
                                pkg = axis.pkg version;
                            in
                            {
                                inherit version pkg;
                                tag = axis.tag version pkg;
                            }
                        ) axis.list;

                    # 组装：把 stack 里的轴做全笛卡尔积
                    # 名称 = 轴名按 stack 顺序用 - 连接
                    # tag  = 各轴 tag 按 stack 顺序用 - 连接
                    mkFamily =
                        { stack }:
                        let
                            defaults = {
                                paths = version: pkg: [ pkg ];
                                env = version: pkg: { };
                                extraCommands = version: pkg: "";
                            };
                            mkOne =
                                combo:
                                let
                                    axis = name: defaults // axes.${name};
                                    value = name: combo.${name};
                                    pathsOf = name: (axis name).paths (value name).version (value name).pkg;
                                    envOf = name: (axis name).env (value name).version (value name).pkg;
                                    extraCommandsOf = name: (axis name).extraCommands (value name).version (value name).pkg;
                                in
                                mkImage {
                                    name = lib.concatStringsSep "-" stack;
                                    tag = lib.concatStringsSep "-" (map (name: (value name).tag) stack);
                                    paths = lib.concatMap pathsOf stack;
                                    env = lib.foldl' (acc: name: acc // envOf name) { } stack;
                                    extraCommands = lib.concatMapStrings extraCommandsOf stack;
                                };
                        in
                        map mkOne (lib.cartesianProduct (lib.genAttrs stack axisValues));

                    nixConf = pkgs.writeText "nix.conf" ''
                        substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org
                        sandbox = false
                        filter-syscalls = false
                        experimental-features = nix-command flakes
                    '';

                    basePaths = [
                        pkgs.bashInteractive
                        pkgs.coreutils
                        pkgs.findutils
                        pkgs.gawk
                        pkgs.gnugrep
                        pkgs.gnused
                        pkgs.gnutar
                        pkgs.gzip
                        pkgs.bzip2
                        pkgs.xz
                        pkgs.zip
                        pkgs.unzip
                        pkgs.curl
                        pkgs.file
                        pkgs.git
                        pkgs.cacert
                        pkgs.tzdata
                    ];

                    baseEnv = {
                        PATH = "/bin";
                        HOME = "/root";
                        TZ = "Asia/Shanghai";
                        SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
                        NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
                    };

                    baseCommands = ''
                        mkdir -m 1777 -p tmp
                        mkdir -p etc/nix etc/ssl/certs root usr/share
                        ln -s ${nixConf} etc/nix/nix.conf
                        ln -s ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt etc/ssl/certs/ca-bundle.crt
                        ln -s ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt etc/ssl/certs/ca-certificates.crt
                        ln -s ${pkgs.tzdata}/share/zoneinfo usr/share/zoneinfo
                    '';

                    mkImage =
                        {
                            name,
                            tag,
                            paths,
                            env ? { },
                            extraCommands ? "",
                        }:
                        {
                            inherit name tag;
                            drv = pkgs.dockerTools.buildLayeredImage {
                                inherit name tag;
                                contents = pkgs.buildEnv {
                                    name = "${name}-root";
                                    paths = basePaths ++ paths;
                                    pathsToLink = [
                                        "/bin"
                                    ];
                                };
                                extraCommands = baseCommands + extraCommands;
                                config = {
                                    Env = lib.mapAttrsToList (key: value: "${key}=${value}") (baseEnv // env);
                                    Cmd = [ "/bin/bash" ];
                                    Labels = {
                                        "org.opencontainers.image.source" = "https://github.com/openhundun/artifact";
                                    };
                                };
                            };
                        };

                    images = lib.concatMap mkFamily [
                        {
                            stack = [ "nix" ];
                        }
                        {
                            stack = [
                                "nix"
                                "go"
                            ];
                        }
                        {
                            stack = [
                                "nix"
                                "bun"
                            ];
                        }
                        {
                            stack = [
                                "nix"
                                "python"
                            ];
                        }
                        {
                            stack = [
                                "nix"
                                "python"
                                "uv"
                            ];
                        }
                        {
                            stack = [
                                "nix"
                                "jdk"
                            ];
                        }
                        {
                            stack = [
                                "nix"
                                "python"
                                "uv"
                                "jdk"
                            ];
                        }
                        {
                            stack = [
                                "nix"
                                "llvm"
                            ];
                        }
                        {
                            stack = [
                                "nix"
                                "llvm"
                                "zig"
                            ];
                        }
                    ];
                in
                lib.listToAttrs (map (image: lib.nameValuePair "${image.name}:${image.tag}" image.drv) images);
        in
        {
            packages = nixpkgs.lib.genAttrs systems (system: mkImages nixpkgs.legacyPackages.${system});
        };
}
