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
, systemdSupport ? true
}: let
  version = "62.0";
in stdenv.mkDerivation {
	pname = "yanet";
	inherit version;

	src = fetchFromGitHub {
		owner = "yanet-platform";
		repo = "yanet";
		rev = "v${version}";
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
}
