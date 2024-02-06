{ stdenv, abseil-cpp, protobuf }:
let
	withoutTests = protobuf.overrideAttrs (super: {
		cmakeFlags = super.cmakeFlags ++ [ "-Dprotobuf_BUILD_TESTS=OFF" ]; 
	});
in withoutTests.override { inherit stdenv abseil-cpp; }
