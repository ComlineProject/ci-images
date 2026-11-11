{
  description = "Bake-off variant nix: the bench image (Rust 1.99.1 minimal, valgrind, iai-callgrind-runner 0.16.1) built with Nix, and a dev shell with the same tools";

  # Every input is pinned by flake.lock (a rev and a narHash each). nixpkgs is
  # the nixos-26.05 release branch (the current stable on 2026-11-12); the
  # lock holds the commit it pointed at when the lock was made.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, nix2container }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ rust-overlay.overlays.default ];
      };
      lib = pkgs.lib;
      n2c = nix2container.packages.${system}.nix2container;

      # Rust 1.99.1, minimal profile (rustc, cargo, rust-std), from rust-overlay.
      rust = pkgs.rust-bin.stable."1.99.1".minimal;
      rustPlatform = pkgs.makeRustPlatform {
        cargo = rust;
        rustc = rust;
      };

      # iai-callgrind-runner 0.16.1, built from the crates.io source (nixpkgs
      # does not package it). The version must match the iai-callgrind crate
      # in core's lockfile.
      iai-callgrind-runner = rustPlatform.buildRustPackage rec {
        pname = "iai-callgrind-runner";
        version = "0.16.1";
        src = pkgs.fetchCrate {
          inherit pname version;
          hash = "sha256-wJTwaqAz8GWCJ/l9GRXYBVBkpPYrWxN4VQ7GdRFXmzM=";
        };
        cargoHash = "sha256-4N7P23bCeeJee/Cm3sSORByh+HzflOENqYqpu629mpA=";
        # Its tests need valgrind and a built benchmark crate.
        doCheck = false;
        meta.mainProgram = "iai-callgrind-runner";
      };

      # The tool set of the other variants (see bakeoff/README.md). The first
      # block is the bench's; the second is what any job container needs
      # (a shell, tar for the cache actions, the usual text tools).
      tools = [
        rust
        iai-callgrind-runner
        pkgs.valgrind
        pkgs.python3
        pkgs.git
        pkgs.gh
        pkgs.stdenv.cc
        pkgs.gnumake
        pkgs.zstd
        pkgs.util-linux # setarch, which iai-callgrind's runner calls
        pkgs.glibc # ldd, getconf
        pkgs.cacert

        pkgs.bashInteractive
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.gawk
        pkgs.gnutar
        pkgs.gzip
      ];

      # Files that are not packages: /usr/bin/env, the loader and libc at the
      # paths other software expects, /etc/os-release and the package list for
      # envinfo.sh. GitHub's mounted node is an ordinary glibc binary: it asks
      # for /lib64/ld-linux-x86-64.so.2, which here is nix-ld, a shim that runs
      # it with Nix's glibc (NIX_LD) and gives it libstdc++ and libgcc_s
      # (NIX_LD_LIBRARY_PATH, below) without touching anything built by Nix.
      # envinfo.sh finds libc at /lib64/libc.so.6.
      skeleton = pkgs.runCommand "skeleton" { } ''
        mkdir -p $out/usr/bin $out/lib64 $out/etc
        ln -s ${pkgs.coreutils}/bin/env $out/usr/bin/env
        ln -s ${pkgs.nix-ld}/libexec/nix-ld $out/lib64/ld-linux-x86-64.so.2
        ln -s ${pkgs.glibc}/lib/libc.so.6 $out/lib64/libc.so.6
        cat > $out/etc/os-release <<'EOF'
        ID=nix-image
        NAME="Nix image"
        PRETTY_NAME="Nix image (nixpkgs nixos-26.05 ${nixpkgs.shortRev or "unknown"})"
        EOF
        printf '%s\n' ${lib.escapeShellArgs (map (p: p.name) tools)} > $out/etc/nix-packages
      '';

      # Everything the image has at /: one environment, links into the store.
      bench-env = pkgs.buildEnv {
        name = "bench-env";
        paths = tools ++ [ pkgs.dockerTools.fakeNss skeleton ];
        pathsToLink = [ "/bin" "/etc" "/usr" "/lib64" ];
        ignoreCollisions = true;
      };

      # Directories open to every uid (the other variants' CARGO_HOME is a+rwX).
      mkDir = path: pkgs.runCommand "dir" { } "mkdir -p $out${path}";
      tmpDir = mkDir "/tmp";
      homeDir = mkDir "/home/ci";
      cargoDir = mkDir "/cargo";
      open = drv: {
        path = drv;
        regex = ".*";
        mode = "0777";
      };

      bench-image = n2c.buildImage {
        name = "ci-bakeoff";
        tag = "nix";
        copyToRoot = [ bench-env tmpDir homeDir cargoDir ];
        perms = map open [ tmpDir homeDir cargoDir ];
        # One layer per popular store path, up to this many (Docker's limit is 127).
        maxLayers = 100;
        config = {
          Env = [
            "PATH=/bin:/usr/bin"
            "HOME=/home/ci"
            # No rustup: cargo and rustc are the pinned toolchain itself, so
            # core's rust-toolchain.toml (channel = "stable") is not consulted.
            "CARGO_HOME=/cargo"
            "CI_RUST_STABLE=1.99.1"
            "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
            "GIT_SSL_CAINFO=/etc/ssl/certs/ca-bundle.crt"
            # For nix-ld, which runs binaries not built by Nix (the runner's node).
            "NIX_LD=${pkgs.glibc}/lib/ld-linux-x86-64.so.2"
            "NIX_LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib"
          ];
          Cmd = [ "/bin/sh" ];
          Labels = {
            "org.opencontainers.image.source" = "https://github.com/ComlineProject/ci-images";
            "org.opencontainers.image.revision" = self.rev or "unknown";
            "org.opencontainers.image.description" = "Base-image bake-off variant nix (not for use)";
          };
        };
      };
    in
    {
      packages.${system} = {
        inherit bench-image bench-env iai-callgrind-runner;
        # The Nix-aware CVE scanner of the bake-off, from the same nixpkgs.
        vulnix = pkgs.vulnix;
        default = bench-image;
      };

      # The same tools, for local use: nix develop
      devShells.${system}.default = pkgs.mkShell {
        packages = tools;
      };
    };
}
