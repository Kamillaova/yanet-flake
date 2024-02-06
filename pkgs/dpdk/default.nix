{ stdenv, lib
, kernel
, fetchurl
, pkg-config, meson, ninja, makeWrapper
, numactl, libbpf, zlib, libelf, jansson, openssl, libpcap
, libbsd, rdma-core
, doxygen, python3, pciutils
, withExamples ? []
, shared ? true
, machine ? "default"
}: let
	mod = kernel != null;
	dpdkVersion = "22.11.2";
in stdenv.mkDerivation {
	pname = "dpdk";
	version = "${dpdkVersion}" + lib.optionalString mod "-${kernel.version}";

	src = fetchurl {
		url = "https://fast.dpdk.org/rel/dpdk-${dpdkVersion}.tar.xz";
		sha256 = "sha256-r2S92hUIf/jUKYlLnqbLu7buepMr2zRPgrDcNmN5otQ=";
	};

	patches = [
		./0001-Increase-PKTMBUF_HEADROOM-to-256.patch
	];

	nativeBuildInputs = [
		makeWrapper
		doxygen
		meson
		ninja
		pkg-config
		python3
		python3.pkgs.sphinx
		python3.pkgs.pyelftools
	];

	buildInputs = [
		jansson
		libbpf
		libelf
		libpcap
		numactl
		openssl.dev
		zlib
		python3
	] ++ lib.optionals mod kernel.moduleBuildDependencies;

	propagatedBuildInputs = [
		# Propagated to support current DPDK users in nixpkgs which statically link
		# with the framework (e.g. odp-dpdk).
		rdma-core
		# Requested by pkg-config.
		libbsd
		openssl
		zlib
		libpcap
		libelf
		jansson
	];

	postPatch = ''
		patchShebangs config/arm buildtools

		# Required by YANET
		sed -Ei 's|(#define RTE_PKTMBUF_HEADROOM) [0-9]+|\1 256|' config/rte_config.h
	'' + lib.optionalString mod ''
		# kernel_install_dir is hardcoded to `/lib/modules`; patch that.
		sed -i "s,kernel_install_dir *= *['\"].*,kernel_install_dir = '$kmod/lib/modules/${kernel.modDirVersion}'," kernel/linux/meson.build
	'';

	enableParallelBuilding = true;

	mesonFlags = [
		"-Dtests=false"
		"-Denable_docs=true"
		"-Denable_driver_sdk=true"
		"-Denable_kmods=${lib.boolToString mod}"
	] ++ [(if shared then "-Ddefault_library=shared" else "-Ddefault_library=static")]
		++ lib.optional (machine != null) "-Dmachine=${machine}"
		++ lib.optional mod "-Dkernel_dir=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
		++ lib.optional (withExamples != []) "-Dexamples=${builtins.concatStringsSep "," withExamples}"
		# kni kernel driver is currently not compatble with 5.11
		++ lib.optional (mod && kernel.kernelOlder "5.11") "-Ddisable_drivers=kni";

	postInstall = ''
		# Remove Sphinx cache files. Not only are they not useful, but they also
		# contain store paths causing spurious dependencies.
		rm -rf $out/share/doc/dpdk/html/.doctrees

		wrapProgram $out/bin/dpdk-devbind.py \
			--prefix PATH : "${lib.makeBinPath [ pciutils ]}"
	'' + lib.optionalString (withExamples != []) ''
		mkdir -p $examples/bin
		find examples -type f -executable -exec install {} $examples/bin \;
	'';

	outputs = [ "out" "dev" "doc" ]
		++ lib.optional mod "kmod"
		++ lib.optional (withExamples != []) "examples";

	meta = with lib; {
		description = "Set of libraries and drivers for fast packet processing";
		homepage = "https://dpdk.org";
		license = with licenses; [ lgpl21 gpl2 bsd2 ];
		platforms =	platforms.linux;
		broken = mod && kernel.isHardened;
		longDescription = ''
			DPDK is a set of libraries and drivers that
			accelerate packet processing and the ability to create
			packet forwarders without the need for costly custom switches and routers.
		'';
	};
}
