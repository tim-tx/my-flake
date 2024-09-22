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
  version = "master-32a36773-git";

  src = fetchFromGitHub {
    owner = "hoytech";
    repo = "strfry";
    rev = "32a367738c6db7430780058c4a6c98b271af73b2";
    fetchSubmodules = true;
    sha256 = "sha256-lHoMyFdN3q+lDks7mxC73l5DXe7nUuq+xoqYlXCrmPs=";
  };

  # patches = [
  #   ./fix-make-rules.patch
  # ];

  buildInputs = [
    flatbuffers
    libb2
    libuv
    lmdb
    openssl
    perl
    perlPackages.RegexpGrammars
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
