{ config, lib, pkgs, ... }:
let
  libconf = import ../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};

  cfg = config.cmn.software.dev;

  lang_profile = {name, initExtra ? "", shellAliases ? {}, add_pkgs ? [], vimplugs ? [], coc-settings ? {}, vimcfg ? ""}:
    {
      inherit name add_pkgs;
      parents = ["software" "dev"];
      home_cfg.programs.bash = {
        inherit initExtra shellAliases;
      };
      cfg.cmn.software.tui.neovim.vimcfg = [
        (libdata.read_data_else_empty ["config" "nvim" "${name}.vim"])
      ] ++ [vimcfg];
      home_cfg.programs.neovim = {
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
    };
    cfg = {
      cmn.software.tui.enable = true;
      cmn.software.tui.git.enable = true;
    };
  }

  (lang_profile {
    name = "rust";
    add_pkgs = with pkgs; [
      (rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" ];
      })
      rust-analyzer
      gcc

      cargo-watch
      clippy
    ];
    vimplugs = with pkgs.vimPlugins; [
      rust-vim
      coc-rust-analyzer
    ];
    coc-settings.rust-analyzer = {
      inlayHints.typeHintsSeparator = "      => ";
      inlayHints.refreshOnInsertMode = true;
      cargo.loadOutDirsFromCheck = true;
      procMacro.enable = true;
    };
    shellAliases = {
      cargo2nix = "nix run github:cargo2nix/cargo2nix --";
      cargocheck = "cargo-watch -c -x 'check --tests'";
    };
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


  # TODO  Nickel dev
  #Plug 'nickel-lang/vim-nickel'

    # "nickel_ls": {
    #   "command": "nls",
    #   "filetypes": [
    #     "nickel",
    #     "ncl"
    #   ]
    # }

  # TODO Complete haskell config
  (lang_profile {
    name = "haskell";
    coc-settings.languageserver.haskell = {
      command = "haskell-language-server";
      args = ["--lsp"];
      rootpatterns = ["*.cabal" "stack.yaml" "cabal.project" "package.yaml" "hie.yaml"];
      filetypes = ["haskell" "lhaskell"];
    };
  })

  # TODO Complete Nix dev
  (lang_profile {
    name = "nix";
    add_pkgs = with pkgs; [
      rnix-lsp
    ];
    vimplugs = with pkgs.vimPlugins; [
      vim-nix
    ];
    coc-settings.languageserver.nix = {
      command = "rnix-lsp";
      filetypes = ["nix"];
    };
  })

  # TODO  Python dev
  (lang_profile {
    name = "python";
    add_pkgs = with pkgs; [
      python310
      python310Packages.pip
      virtualenv
      poetry
    ];
    vimplugs = with pkgs.vimPlugins; [
    ];
    # coc-settings.languageserver.python = {
    # };
  })
]
