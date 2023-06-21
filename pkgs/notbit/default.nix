{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, pkg-config
, openssl
}:

stdenv.mkDerivation {
  name = "notbit";
  version = "master-7f50ab3d-git";

  src = fetchFromGitHub {
    owner = "bpeel";
    repo = "notbit";
    rev = "7f50ab3dcc3344c7fc9c4740cd50924a9d128c6f";
    sha256 = "sha256-cziRNwvpi6MZ16UQPUQTxVuAprgRq3zGErcKsHPhMb8=";
  };

  nativeBuildInputs = [
    autoreconfHook pkg-config
  ];

  buildInputs = [
    openssl
  ];

  meta = with lib; {
    homepage = "https://github.com/bpeel/notbit";
    description = "A minimal Bitmessage client";
    platforms = platforms.linux;
    license = licenses.mit;
  };
}
