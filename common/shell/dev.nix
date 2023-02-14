{ config, lib, pkgs, pkgs_unstable, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};

  cfg = config.cmn.software.dev;

  lang_profile = {
    name,
    initExtra ? "",
    shellAliases ? {},
    add_pkgs ? [],
    vimplugs ? [],
    coc-settings ? {},
    vimcfg ? "",
    helixlang ? "",
  }:
    {
      inherit name add_pkgs;
      parents = ["software" "dev"];
      cfg = {
        environment.interactiveShellInit = initExtra;
        environment.shellAliases = shellAliases;
        cmn.software.tui.neovim = lib.mkIf config.cmn.software.tui.neovim.enable {
          vimcfg = [
            (libdata.read_data_else_empty ["config" "nvim" "${name}.vim"])
          ] ++ [vimcfg];
          add_plugins = vimplugs;
        };
        cmn.software.tui.helix.languagesdef = [ ''
          [[language]]
          name = "${name}"
          ${helixlang}
        ''];
      };
      home_cfg.programs.neovim = lib.mkIf config.cmn.software.tui.neovim.enable {
        plugins = vimplugs;
        coc.settings = coc-settings;
      };
    };
in
libconf.create_common_confs [
  {
    name = "dev";
    parents = ["software"];
    chain_enable_opts  = {
      basic = [ "rust" "nix" "python" ];
      scripts = ["python"];
      software = ["rust" "python"];
      functionnal = ["ocaml" "haskell"];
      system = ["c" "nix" "python"];
      web = ["svelte"];
    };
    add_pkgs = with pkgs; [
      pkg-config
      binutils
      bintools

      openssl.dev
      openssl_3.dev
      dbus.dev
    ];
    cfg = {
      environment.variables.OPENSSL_DEV = "${pkgs.openssl.dev}";
      environment.variables.PKG_CONFIG_PATH = "$PKG_CONFIG_PATH:${pkgs.openssl.dev}/lib/pkgconfig";
      cmn.software.tui.enable = true;
      cmn.software.tui.git.enable = true;
    };
  }

  (lang_profile {
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
    helixlang = ''
      language-server = { command = "${pkgs_unstable.rust-analyzer}/bin/rust-analyzer" }
    '';
  })

  (lang_profile {
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
  })

  (lang_profile {
    name = "haskell";
    coc-settings.languageserver.haskell = {
      command = "haskell-language-server";
      args = ["--lsp"];
      rootpatterns = ["*.cabal" "stack.yaml" "cabal.project" "package.yaml" "hie.yaml"];
      filetypes = ["haskell" "lhaskell"];
    };
  })

  (lang_profile {
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
      lsp = ${pkgs_unstable.nil}/bin/nil;
    in ''
      language-server = { command = "${lsp}" }
    '';
  })

  (let
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
      lsp = ${pkgs_unstable.python310Packages.python-lsp-server}/bin/pylsp;
    in ''
      language-server = { command = "${lsp}" }
    '';
  })

  (lang_profile {
    name = "c";
    add_pkgs = with pkgs_unstable; [
      clang-tools
    ];
    vimplugs = with pkgs_unstable.vimPlugins; [
      coc-clangd
    ];
  })

  (lang_profile {
    name = "svelte";
    vimplugs = with pkgs_unstable.vimPlugins; [
      vim-svelte
    ];
    helixlang = let
      lsp = "${pkgs_unstable.nodePackages.svelte-language-server}/bin/svelteserver";
    in ''
      language-server = { command = "${lsp}" }
    '';
  })
]
