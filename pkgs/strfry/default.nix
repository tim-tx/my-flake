{ lib
, stdenv
, fetchFromGitHub
, flatbuffers
, libb2
, libuv
, lmdb
, openssl
, perl
, perlPackages
, secp256k1
, zlib
, zstd
}:

stdenv.mkDerivation {
  pname = "strfry";
  version = "master-f192adb4-git";

  src = fetchFromGitHub {
    owner = "hoytech";
    repo = "strfry";
    rev = "f192adb4982279f730c35f3d255cd75301239466";
    fetchSubmodules = true;
    sha256 = "sha256-KIuEOQZYwuzN0HskQmO7vyfAO/W0ye5pJO6IunY/PDg=";
  };

  patches = [
    ./fix-make-rules.patch
  ];

  buildInputs = [
    flatbuffers
    libb2
    libuv
    lmdb
    openssl
    perl
    perlPackages.TemplateToolkit
    perlPackages.YAML
    secp256k1
    zlib
    zstd
  ];

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp strfry $out/bin
  '';

  meta = with lib; {
    homepage = "https://github.com/hoytech/strfry";
    description = "A nostr relay";
    platforms = platforms.linux;
    license = licenses.gpl3;
  };
}
