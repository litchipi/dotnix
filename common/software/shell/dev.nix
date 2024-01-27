{ config, lib, pkgs, pkgs_unstable, ... }:
let
  libdata = import ../../../lib/manage_data.nix {inherit config lib pkgs;};

  cfg = config.software.dev;

  lang_profile = {
    name,
    initExtra ? "",
    shellAliases ? {},
    add_pkgs ? [],
    vimplugs ? [],
    coc-settings ? {},
    vimcfg ? "",
    helixlang ? "",
  }: let
    all_confs = {
      neovim = {
        vimcfg = [
          (libdata.read_data_else_empty ["config" "nvim" "${name}.vim"])
        ] ++ [vimcfg];
        add_plugins = vimplugs;
      };
      helix = {
        languagesdef = [''
          [[language]]
          name = "${name}"
          ${helixlang}
        ''];
      };
    };
    all_home_confs = {
      neovim = {
        programs.neovim = lib.mkIf (builtins.hasAttr "neovim" config.software.tui) {
          plugins = vimplugs;
          coc.settings = coc-settings;
        };
      };
    };
  in {
    environment = {
      systemPackages = add_pkgs;
      interactiveShellInit = initExtra;
      shellAliases = shellAliases;
    };

    software.tui = lib.mkMerge (lib.attrsets.mapAttrsToList (name: conf:
      if (builtins.hasAttr name config.software.tui) then { ${name} = conf; } else {}
    ) all_confs);

    base.home_cfg = lib.mkMerge (lib.attrsets.mapAttrsToList (name: conf:
      if (builtins.hasAttr name config.software.tui) then conf else {}
    ) all_home_confs);
  };

  mkProfilesOptions = profiles: builtins.mapAttrs (name: _:
    lib.mkEnableOption { description = "Enable the profile ${name}"; }
  ) profiles;

  mkProfilesConfig = profiles: lib.attrsets.mapAttrsToList (name: profile:
    lib.mkIf cfg.profiles.${name} profile
  ) profiles;

  all_profiles = {
    rust = lang_profile {
      name = "rust";
      add_pkgs = with pkgs_unstable; [
        gcc
        (rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" ];
        })
        cargo-watch
        clippy
      ];
      vimplugs = with pkgs_unstable.vimPlugins; [
        rust-vim
        coc-rust-analyzer
      ];
      coc-settings.rust-analyzer = {
        inlayHints.typeHintsSeparator = "      => ";
        inlayHints.refreshOnInsertMode = true;
        cargo.loadOutDirsFromCheck = true;
        procMacro.enable = true;
        serverPath = "${pkgs_unstable.rust-analyzer}/bin/rust-analyzer";
      };
      shellAliases = {
        cargo2nix = "nix run github:cargo2nix/cargo2nix --";
        cargocheck = "cargo-watch -c -x 'check --tests'";
      };
      helixlang = let
        lsp = "${pkgs_unstable.rust-analyzer}/bin/rust-analyzer";
      in ''
        language-servers = ["rust-analyzer"]

        [language-server.rust-analyzer]
        command = "${lsp}"
        timeout = 60
        cachePriming.enable = false

        [language-server.rust-analyzer.config]
        cargo = { features = "all" }

        [language-server.rust-analyzer.inlayHints]
        closingBraceHints = true
        closureReturnTypeHints.enable = "skip_trivial"
        parameterHints.enable = false
        typeHints.enable = true
        inlayHints.maxLength = 10
      '';
    };

    ocaml = lang_profile {
      name = "ocaml";
      add_pkgs = with pkgs.ocamlPackages; [
        merlin
        lsp
        opam-format
        pkgs.opam
        dune-release
      ];
      coc-settings.languageserver.ocaml-lsp = {
        command = "opam";
        args = ["config" "exec" "--" "ocamllsp"];
        filetypes = ["ocaml" "reason"];
      };
    };

    haskell = lang_profile {
      name = "haskell";
      coc-settings.languageserver.haskell = {
        command = "haskell-language-server";
        args = ["--lsp"];
        rootpatterns = ["*.cabal" "stack.yaml" "cabal.project" "package.yaml" "hie.yaml"];
        filetypes = ["haskell" "lhaskell"];
      };
    };

    nix = lang_profile {
      name = "nix";
      add_pkgs = with pkgs_unstable; [
        rnix-lsp
        manix
      ];
      vimplugs = with pkgs_unstable.vimPlugins; [
        vim-nix
      ];
      coc-settings.languageserver.nix = {
        command = "rnix-lsp";
        filetypes = ["nix"];
      };
      helixlang = let
        lsp = "${pkgs_unstable.nil}/bin/nil";
      in ''
        language-servers = ["nil"]

        [language-server.nil]
        command = "${lsp}"
      '';
    };

    python = let
      pythonpkg = pkgs.python310.withPackages (p: with p; [
        pip
        virtualenv
        requests
      ]);
    in lang_profile {
      name = "python";
      # TODO    Add an alias that generate a virtualenv with some packages automatically installed
      add_pkgs = with pkgs; [
        pythonpkg
        poetry
        black
      ];
      vimplugs = with pkgs_unstable.vimPlugins; [
        coc-pyright
      ];
      coc-settings.python = {
        pythonPath = "${pythonpkg}/bin/python3";
        pyright.server = "${pkgs.nodePackages.pyright}/bin/pyright";
      };
      helixlang = let
        lsp = "${pkgs_unstable.python310Packages.python-lsp-server}/bin/pylsp";
      in ''
        language-servers = ["pylsp"]

        [language-server.pylsp]
        command = "${lsp}"
      '';
    };

    c = lang_profile {
      name = "c";
      add_pkgs = with pkgs_unstable; [
        clang-tools
      ];
      vimplugs = with pkgs_unstable.vimPlugins; [
        coc-clangd
      ];
    };

    svelte = lang_profile {
      name = "svelte";
      vimplugs = with pkgs_unstable.vimPlugins; [
        vim-svelte
      ];
      helixlang = let
        lsp = "${pkgs_unstable.nodePackages_latest.svelte-language-server}/bin/svelteserver";
      in ''
        language-servers = ["svelteserver"]

        [language-server.svelteserver]
        command = "${lsp}"
        indent = { tab-width = 4, unit = "    " }
      '';
    };

    typescript = lang_profile {
      name = "typescript";
      helixlang = let
        lsp = "${pkgs_unstable.nodePackages_latest.typescript-language-server}/bin/typescript-language-server";
      in ''
        language-servers = ["typescript-lsp"]

        [language-server.typescript-lsp]
        command = "${lsp}"
        args = ["--stdio"]
      '';
    };
  };
in
  {
    imports = [ ./tui.nix ];
    options.software.dev = {
      profiles = mkProfilesOptions all_profiles;
    };
    config = lib.mkMerge ((mkProfilesConfig all_profiles) ++ [{
      environment.systemPackages = with pkgs; [
        pkg-config
        binutils
        bintools
        openssl.dev
        openssl_3.dev
        dbus.dev
      ];
      environment.variables.OPENSSL_DEV = "${pkgs.openssl.dev}";
      environment.variables.PKG_CONFIG_PATH = "$PKG_CONFIG_PATH:${pkgs.openssl.dev}/lib/pkgconfig";
    }]);
  }
