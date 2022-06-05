{pkgs, ...}: {
  nixpkgs.overlays = [ (self: super: {
    powerline-go = super.powerline-go.overrideAttrs (old: {
      patches = (old.patches or []) ++ [ ./nix-powerline-go.patch ];
    });
  }) ];

  targets.genericLinux.enable = true;

  services.gpg-agent.enable = true;

  home.packages = with pkgs; [
    curl
    zip
    unzip
    silver-searcher
    yt-dlp
    ctags   # for nvim plugin
    sysstat # for tmux-cpu
    (writeScriptBin "nixFlakes" ''
      exec ${pkgs.nixUnstable}/bin/nix --experimental-features "nix-command flakes" "$@"
    '')
  ];

  home.file.".gdbinit".text = ''
    set auto-load safe-path /nix/store
  '';

  programs = {
    home-manager.enable = true;

    htop.enable = true;
    gpg.enable = true;
    aria2.enable = true;
    dircolors.enable = true;
    info.enable = true;
    lesspipe.enable = true;
    nix-index.enable = true;
    man.enable = true;
    bottom.enable = true;

    vscode = {
      enable = true;
      package = pkgs.vscodium;
      mutableExtensionsDir = true;
      userSettings = {
        "editor.fontSize" = 12;
        "editor.formatOnSave" = true;
        "editor.formatOnSaveMode" = "modificationsIfAvailable";
        "editor.inlayHints.enabled" = true;
        "errorLens.statusBarIconsEnabled" = false;
        "errorLens.statusBarMessageEnabled" = false;
        "rust-analyzer.checkOnSave.command" = "clippy";
        "rust-analyzer.hoverActions.references" = true;
        "rust-analyzer.inlayHints.chainingHints" = true;
        "rust-analyzer.inlayHints.closureReturnTypeHints" = true;
        "rust-analyzer.inlayHints.enable" = true;
        "rust-analyzer.inlayHints.lifetimeElisionHints.enable" = "always";
        "rust-analyzer.inlayHints.maxLength" = null;
        "rust-analyzer.inlayHints.parameterHints" = true;
        "rust-analyzer.inlayHints.typeHints" = true;
        "rust-analyzer.lens.enumVariantReferences" = true;
        "rust-analyzer.lens.methodReferences" = true;
        "rust-analyzer.lens.references" = true;
        "update.mode" = "none";
        "vim.enableNeovim" = true;
        "vim.hlsearch" = true;
        "window.zoomLevel" = 1;
        "workbench.colorTheme" = "Default Dark+";
        "workbench.iconTheme" = "vscode-great-icons";
        "workbench.startupEditor" = "none";
      };
      extensions = with pkgs.vscode-extensions; [
        vscodevim.vim
        gruntfuggly.todo-tree
        yzhang.markdown-all-in-one
        bbenoist.nix
        serayuzgur.crates
        eamodio.gitlens
        coenraads.bracket-pair-colorizer
        emmanuelbeziat.vscode-great-icons
        #streetsidesoftware.code-spell-checker
        usernamehw.errorlens
        oderwat.indent-rainbow
        #matklad.rust-analyzer                 # rust
        vadimcn.vscode-lldb                   # rust
        bungcip.better-toml                   # rust
        #ms-vscode.cpptools                    # cpp
        xaver.clang-format                    # cpp
        #notskm.clang-tidy                     # cpp
        llvm-vs-code-extensions.vscode-clangd # cpp
        #denniskempin.vscode-include-fixer     # cpp
      ];
    };

    powerline-go = {
      enable = true;
      newline = true;
      modules = ["time" "host" "cwd" "jobs" "git" "nix-shell" "exit" ];
      settings = {
        colorize-hostname = true;
        hostname-only-if-ssh = true;
        cwd-mode = "plain";
        mode = "compatible";
        numeric-exit-codes = true;
      };
    };

    tmux = {
      enable = true;
      clock24 = true;
      historyLimit = 50000;
      keyMode = "vi";
      prefix = "C-j";
      shortcut = "j";
      aggressiveResize = true;
      terminal = "tmux-256color";
      extraConfig = ''
        set -g display-time 4000
        set -g status-interval 5

        setw -g monitor-activity on
        setw -g visual-activity on

        setw -g window-status-current-style fg=black,bg=yellow

        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        bind e last-window

        bind c new-window -c "#{pane_current_path}"

        set-option -sg escape-time 10

        set-option -sa terminal-overrides ',tmux-256color:RGB'
      '';
      plugins = with pkgs; [
        {
          plugin = tmuxPlugins.cpu;
          extraConfig = ''
            set -g status-left-length 50
            set -g @cpu_percentage_format "%5.1f%%"
            set -g status-left '#S #{cpu_bg_color}#{cpu_percentage} #{ram_bg_color}#{ram_percentage} '
          '';
        }
      ];
    };

    mpv = {
      enable = true;
      package = pkgs.wrapMpv (pkgs.mpv-unwrapped.override { vapoursynthSupport = true; }) {
        youtubeSupport = true;
      };
    };

    bash = {
      enable = true;
      enableVteIntegration = true;
      sessionVariables = {
        EDITOR = "vi";
        TERM = "xterm-256color";
        PS1 = ''\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$(__git-branch-prompt)\$ '';
      };
      initExtra = ''
        function __git-branch-prompt {
          local branch=$(git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3-)
          [ -z "$branch" ] || printf " [%s]" $branch
        }
        if [ "$IN_NIX_SHELL" == "pure" ]; then
          if [ -x "$HOME/.nix-profile/bin/powerline-go" ]; then
            alias powerline-go="$HOME/.nix-profile/bin/powerline-go"
          elif [ -x "/run/current-system/sw/bin/powerline-go" ]; then
            alias powerline-go="/run/current-system/sw/bin/powerline-go"
          fi
        fi

        function nix-index-update {
          (
            filename="index-x86_64-$(uname | tr A-Z a-z)"
            mkdir -p ~/.cache/nix-index
            cd ~/.cache/nix-index
            # -N will only download a new version if there is an update.
            wget -q -N https://github.com/Mic92/nix-index-database/releases/latest/download/$filename
            ln -f $filename files
          )
        }
      '';
      logoutExtra = ''
        [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
      '';
      shellAliases = {
        ls = "ls --color=auto";
        grep = "grep --color=auto";
        egrep = "egrep --color=auto";
        fgrep = "fgrep --color=auto";
        ll = "ls -alF";
        yt-dlp-list = "yt-dlp -o '%(playlist_index)03d-%(title)s-%(id)s.%(ext)s'";
      };
    };

    git = {
      enable = true;
      package = pkgs.gitAndTools.gitFull;
      userName = "Mo Xiaoming";
      userEmail = "2188767+mo-xiaoming@users.noreply.github.com";
      ignores = [ "*.swp" ];
      signing = {
        key = "2B2FF1E29E07A36B";
        signByDefault = true;
      };
      extraConfig = {
        core.editor = "vi";
        pull = {
          rebase = true;
          ff = "only";
        };
        rebase.autoStash = true;
        diff.tool = "vimdiff";
        merge.tool = "vimdiff";
        difftool.prompt = false;
        init.defaultBranch = "main";
      };
    };

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;
      withPython3 = true;
      plugins = with pkgs.vimPlugins;
      let
        vim-lsp-cxx-highlight = pkgs.vimUtils.buildVimPlugin {
          name = "vim-lsp-cxx-highlight";
          src = pkgs.fetchFromGitHub {
            owner = "jackguo380";
            repo = "vim-lsp-cxx-highlight";
            rev = "0e7476ff41cd65e55f92fdbc7326335ec33b59b0";
            sha256 = "1nsac8f2c0lj42a77wxcv3k6i8sbpm5ghip6nx7yz0dj7zd4xm10";
          };
        };
        vim-syntax-extra = pkgs.vimUtils.buildVimPlugin {
          name = "vim-syntax-extra";
          src = pkgs.fetchFromGitHub {
            owner = "justinmk";
            repo = "vim-syntax-extra";
            rev = "5906eeab33e1e50ebf13b6fbbb4442e22f67b2b2";
            sha256 = "1nsac8f2c0lj42a77wxcv3k6i8sbpm5ghip6nx7yz0dj7zd4xm10";
          };
        };
      in [
        vim-nix
        #coc-nvim
        #coc-clangd # :CocCommand clangd.install
        vim-lsp-cxx-highlight
        #taglist-vim
        coc-explorer
        coc-json
        coc-spell-checker
        rainbow
        vim-airline
        vim-signify
        git-blame-nvim
        ctrlp-vim
        vim-syntax-extra
        vim-gutentags # ctags not in path error
        vim-localvimrc
        tagbar
        fzf-vim
        minimap-vim
      ];

      coc = {
        enable = true;
        package = pkgs.vimUtils.buildVimPluginFrom2Nix {
          pname = "coc.nvim";
          version = "2022-05-21";
          src = pkgs.fetchFromGitHub {
            owner = "neoclide";
            repo = "coc.nvim";
            rev = "791c9f673b882768486450e73d8bda10e391401d";
            sha256 = "sha256-MobgwhFQ1Ld7pFknsurSFAsN5v+vGbEFojTAYD/kI9c=";
          };
          meta.homepage = "https://github.com/neoclide/coc.nvim/";
        };
        settings = {
          "suggest.noselect" = true;
          "suggest.enablePreview" = true;
          "suggest.enablePreselect" = false;
          "suggest.disableKind" = true;
          "suggest.removeDuplicateItems" = true;
          "diagnostic.checkCurrentLine" = true;
          "diagnostic.separateRelatedInformationAsDiagnostics" = true;
          "diagnostic.floatConfig" = {
            "border" = true;
            "title" = "diagnostic";
          };
          "hover.floatConfig" = {
            "border" = true;
            "title" = "hover";
          };
          "signature.floatConfig" = {
            "border" = true;
            "title" = "signature";
          };
          "suggest.floatConfig" = {
            "border" = true;
            "title" = "suggest";
          };
          "coc.preferences.formatOnType" = true;
          "coc.preferences.enableMessageDialog" = true;
          "coc.preferences.extensionUpdateCheck" = "daily";
          "coc.preferences.semanticTokensHighlights" = false;
          "coc.preferences.colorSupport" = true;
          "coc.preferences.currentFunctionSymbolAutoUpdate" = true;
          "coc.preferences.formatOnSaveFiletypes" = [ "rust" ];
          #"clangd.path" = "~/.config/coc/extensions/coc-clangd-data/install/14.0.3/clangd_14.0.3/bin/clangd";
          "clangd.semanticHighlighting" = true;
          "clangd.fallbackFlags" = [ "-std=gnu++17" "-Wall" "-Wextra" "-Wshadow" ];
          "rust-analyzer.experimental.procAttrMacros" = true;
          "rust-analyzer.cargo.allFeatures" = true;
          "rust-analyzer.procMacro.enable" = true;
          "rust-analyzer.lens.methodReferences" = true;
          "rust-analyzer.hoverActions.linksInHover" = true;
          "rust-analyzer.assist.importEnforceGranularity" = true;
          "rust-analyzer.inlayHints.refreshOnInsertMode" = true;
          "rust-analyzer.rustfmt.enableRangeFormatting" = true;
          "rust-analyzer.checkOnSave.command" = "clippy";
          "sumneko-lua.enableNvimLuaDev" = true;
          "sumneko-lua.inlayHints.refreshOnInsertMode" = true;
          "Lua.IntelliSense.traceBeSetted" = true;
          "Lua.IntelliSense.traceFieldInject" = true;
          "Lua.IntelliSense.traceLocalSet" = true;
          "Lua.IntelliSense.traceReturn" = true;
          "Lua.hint.setType" = true;
          languageserver = {
            haskell = {
              command = "haskell-language-server-wrapper";
              args = [ "--lsp" ];
              rootPatterns = [
                "*.cabal"
                "stack.yaml"
                "cabal.project"
                "package.yaml"
                "hie.yaml"
              ];
              filetypes = [ "haskell" "lhaskell" ];
            };
          };
        };
      };
      extraConfig = builtins.readFile ./vim-files/nvim-hm.vim;
    };
  };
  xdg.configFile."nvim/syntax/hobbes.vim".source = ./vim-files/hobbes.vim;
  xdg.configFile."nvim/syntax/antlr4.vim".source = ./vim-files/antlr4.vim;

  xdg.configFile."yt-dlp/config".text = ''
    --retries infinite --fragment-retries infinite --format 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'
  '';
}
