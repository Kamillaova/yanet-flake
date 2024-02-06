let
	lock = builtins.fromJSON (builtins.readFile ./flake.lock);

	flake-compat-rev = lock.nodes.flake-compat.locked.rev;

	flake-compat = fetchTarball {
		url = "https://github.com/edolstra/flake-compat/archive/${flake-compat-rev}.tar.gz";
		sha256 = lock.nodes.flake-compat.locked.narHash;
	};
in (import flake-compat { src = ./.; }).defaultNix
