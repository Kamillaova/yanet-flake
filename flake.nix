{
	description = "Flake for YANET";

	nixConfig = {
		extra-substituters = "https://kamillaova.cachix.org";
		extra-trusted-public-keys = "kamillaova.cachix.org-1:TRQAuNhP6TO2CCl2Jen94Cx4tGpaBtha8o97NRgbngY=";
	};

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-parts.url = "github:hercules-ci/flake-parts";
		systems.url = "github:nix-systems/default";
	};

	outputs = inputs @ { flake-parts, ... }: 
		flake-parts.lib.mkFlake { inherit inputs; } {
			imports = [
				flake-parts.flakeModules.easyOverlay
			];
		
			systems = import inputs.systems;

			perSystem = { config, pkgs, ... }: {
				overlayAttrs = {
					inherit (config.packages) yanet;
				};

				packages = rec {
					dpdk = pkgs.callPackage ./pkgs/dpdk { kernel = null; };
					yanet = pkgs.callPackage ./pkgs/yanet { inherit dpdk; };

					default = yanet;
				};
			};
		};
}
