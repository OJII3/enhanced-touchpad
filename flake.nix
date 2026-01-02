{
  description = "Enhanced Touchpad - Mac-like touchpad experience for Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
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
        };

      flake = {
        # Home Manager module
        homeManagerModules.default = { config, lib, pkgs, ... }:
          let
            cfg = config.programs.enhanced-touchpad;

            pythonEnv = pkgs.python3.withPackages (ps: with ps; [
              evdev
            ]);

            enhanced-touchpad = pkgs.writeShellScriptBin "enhanced-touchpad" ''
              exec ${pythonEnv}/bin/python3 ${./enhanced-touchpad.py} "$@"
            '';
          in
          {
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

            config = lib.mkIf cfg.enable {
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
                    + lib.optionalString cfg.verbose " -v"
                    + lib.optionalString (cfg.device != null)
                      " --device ${cfg.device}";
                  Restart = "on-failure";
                  RestartSec = "5s";
                };

                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
              };
            };
          };
      };
    };
}
