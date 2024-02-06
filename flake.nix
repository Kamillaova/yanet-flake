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

			perSystem = { config, pkgs, ... }: let 
				stdenv = pkgs.gcc11Stdenv; # YANET requires gcc 11 or older
			in {
				overlayAttrs = {
					inherit (config.packages) yanet;
				};

				packages = rec {
					abseil-cpp = pkgs.callPackage ./pkgs/abseil-cpp { inherit stdenv; };
					protobuf = pkgs.callPackage ./pkgs/protobuf { inherit stdenv abseil-cpp; };
					dpdk = pkgs.callPackage ./pkgs/dpdk { kernel = null; };
					yanet = pkgs.callPackage ./pkgs/yanet { inherit stdenv protobuf dpdk; };

					default = yanet;
				};
			};
		};
}
