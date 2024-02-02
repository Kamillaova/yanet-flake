{
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
					abseil-cpp = pkgs.callPackage ./packages/abseil-cpp { inherit stdenv; };
					protobuf = pkgs.callPackage ./packages/protobuf { inherit stdenv abseil-cpp; };
					dpdk = pkgs.callPackage ./packages/dpdk { kernel = null; };
					yanet = pkgs.callPackage ./packages/yanet { inherit stdenv protobuf dpdk; };

					default = yanet;
				};
			};
		};
}
