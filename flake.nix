{
  description = "Enhanced Touchpad - Mac-like touchpad experience for Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          evdev
        ]);

        enhanced-touchpad = pkgs.writeShellScriptBin "enhanced-touchpad" ''
          exec ${pythonEnv}/bin/python3 ${./enhanced-touchpad.py} "$@"
        '';

      in
      {
        packages = {
          default = enhanced-touchpad;
          enhanced-touchpad = enhanced-touchpad;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.python3Packages.python-lsp-server
          ];

          shellHook = ''
            echo "Enhanced Touchpad Development Environment"
            echo "Run: python enhanced-touchpad.py --help"
          '';
        };

        # Home Manager module
        homeManagerModules.default = { config, lib, pkgs, ... }: {
          options.programs.enhanced-touchpad = {
            enable = lib.mkEnableOption "Enhanced Touchpad";

            verbose = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable verbose logging";
            };

            device = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Touchpad device path (auto-detect if null)";
            };
          };

          config = lib.mkIf config.programs.enhanced-touchpad.enable {
            home.packages = [ enhanced-touchpad ];

            systemd.user.services.enhanced-touchpad = {
              Unit = {
                Description = "Enhanced Touchpad Filter Daemon";
                After = [ "graphical-session.target" ];
                PartOf = [ "graphical-session.target" ];
              };

              Service = {
                Type = "simple";
                ExecStart = "${enhanced-touchpad}/bin/enhanced-touchpad"
                  + lib.optionalString config.programs.enhanced-touchpad.verbose " -v"
                  + lib.optionalString (config.programs.enhanced-touchpad.device != null)
                    " --device ${config.programs.enhanced-touchpad.device}";
                Restart = "on-failure";
                RestartSec = "5s";
              };

              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };
          };
        };
      }
    );
}
