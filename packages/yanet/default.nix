{ lib
, stdenv
, fetchFromGitHub

# Build tools
, meson
, ninja
, pkg-config
, flex
, bison

# Run-time dependencies
, dpdk
, libnl
, protobuf
, systemdLibs
, nlohmann_json
, yaml-cpp
, numactl

# Options
, versionType ? "stable"
, yanetConfig ? "release"
, systemdSupport ? true
}: let
  version = "62.0";
  commit = "da7e39895bab3422e52e6cb6ac91f0db4ed1ef9d";
in stdenv.mkDerivation {
	pname = "yanet";
	inherit version;

	src = fetchFromGitHub {
		owner = "yanet-platform";
		repo = "yanet";
		rev = commit;
		hash = "sha256-dPo71Z1VUmyD5+D7p11yRSiBTZRDKYyp1n1BnPKtTlg=";
	};

	patches = [
		./0001-Disable-static-linking.patch
		./0002-Disable-LTO.patch
		./0003-Fix-string-bound-errors.patch
		./0004-Workaround-protobuf-final.patch
		./0005-Fix-stream-uninitialized-error.patch
		./0006-Add-numa-dependency.patch
	] ++ lib.optional (!systemdSupport) ./0007-Disable-systemd-support.patch;

	enableParallelBuilding = true;

	mesonFlags = let
		versionMatch = builtins.match "^([0-9]+)\.([0-9]+)$" version;
		versionMajor = builtins.elemAt versionMatch 0;
		versionMinor = builtins.elemAt versionMatch 1;
	in [
		"-Dyanet_config=${yanetConfig}"
		"-Dversion_major=${versionMajor}"
		"-Dversion_minor=${versionMinor}"
		"-Dversion_revision=1"
		"-Dversion_hash=${commit}"
		"-Dversion_custom=${versionType}"
	];

	nativeBuildInputs = [ meson ninja pkg-config flex bison ];

	buildInputs = [
		dpdk.dev
		libnl.dev
		protobuf
		nlohmann_json
		numactl.dev
		yaml-cpp
	] ++ lib.optional systemdSupport systemdLibs;

	passthru = {
		inherit dpdk protobuf;
	};

	meta = with lib; {
		description = "A high performance framework for forwarding traffic based on DPDK";
		homepage = "https://github.com/yanet-platform/yanet";
		license = with licenses; [ asl20 ];
		platforms =	platforms.linux;
	};
}
