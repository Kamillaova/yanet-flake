{ stdenv, abseil-cpp }:
abseil-cpp.override {
	inherit stdenv;
}
