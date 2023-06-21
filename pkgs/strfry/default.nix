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
  version = "master-e4e79af1-git";

  src = fetchFromGitHub {
    owner = "hoytech";
    repo = "strfry";
    rev = "e4e79af1214e38ea90f4d099bd1f057a688abdb6";
    fetchSubmodules = true;
    sha256 = "sha256-jWhiYKuFcAOHNIo9wtH/B0rArz1S+XAEtVlWAGif/CA=";
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
