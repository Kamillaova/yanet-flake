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
  version = "63.0";
  commit = "535ec75b895faa76eceb6711e21795bd4fef4932";
in stdenv.mkDerivation {
	pname = "yanet";
	inherit version;

	src = fetchFromGitHub {
		owner = "yanet-platform";
		repo = "yanet";
		rev = commit;
		hash = "sha256-+sZ18cBBlUv4igeN0tefv6ySLe1t8j+RODjnmyk5hck=";
	};

	patches = [
		./0001-Disable-static-linking.patch
		./0002-Disable-LTO.patch
		./0003-Fix-building-on-new-compilers.patch
		./0004-Fix-string-bound-errors.patch
		./0005-Fix-protobuf-final.patch
		./0006-Add-cstdint-include.patch
		./0007-Add-numa-dependency.patch
		./0008-Minor-changes.patch
	] ++ lib.optional (!systemdSupport) ./0009-Disable-systemd-support.patch;

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
		dpdk
		libnl
		numactl
		yaml-cpp
		protobuf
		nlohmann_json
	] ++ lib.optional systemdSupport systemdLibs;

	passthru = { inherit dpdk; };

	meta = with lib; {
		description = "A high performance framework for forwarding traffic based on DPDK";
		homepage = "https://github.com/yanet-platform/yanet";
		license = with licenses; [ asl20 ];
		platforms =	platforms.linux;
		longDescription = ''
			YANET is an open-source extensible framework for
			software forwarding traffic based on DPDK.
		'';
	};
}
