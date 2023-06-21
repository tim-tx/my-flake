{ lib
, fetchFromGitHub
, haskell
}:

let
  hp = haskell.packages.ghc8107.override {
    overrides = self: super: rec {
      # iproute tests afflicted by https://discourse.haskell.org/t/facing-mmap-4096-bytes-at-nil-cannot-allocate-memory-youre-not-alone/6259
      iproute = haskell.lib.dontCheck super.iproute;

      # otherwise errors of "indirectly depends on multiple versions of the same package" appear, with "Cabal-3.2.1.0 compiled by ghc-8.10"
      Cabal = self.callHackageDirect {
        pkg = "Cabal";
        ver = "3.2.1.0";
        sha256 = "sha256-JOCRdwvNSAg5MU4z2sNbyJohnlo2XkNqV0mp9G0aoPE=";
      } {};

      aeson = self.callCabal2nix "aeson" (fetchFromGitHub {
        owner = "simplex-chat";
        repo = "aeson";
        rev = "3eb66f9a68f103b5f1489382aad89f5712a64db7";
        sha256 = "sha256-15P7raShOOp8XGm2Be6wxA2G6safyTk8HsxQl0qfNE4=";
      }) {};
      direct-sqlcipher = self.callCabal2nix "direct-sqlcipher" (fetchFromGitHub {
        owner = "simplex-chat";
        repo = "direct-sqlcipher";
        rev = "34309410eb2069b029b8fc1872deb1e0db123294";
        sha256 = "sha256-zTlbfYHi2YzgX8r46c6Ur8CQX9Ul0Edbj1RY7Tysk08=";
        fetchSubmodules = true;
      }) {};
      socks = self.callCabal2nix "socks" (fetchFromGitHub {
        owner = "simplex-chat";
        repo = "hs-socks";
        rev = "a30cc7a79a08d8108316094f8f2f82a0c5e1ac51";
        sha256 = "sha256-aEgouR5om+yElV5efcsLi+4plvq7qimrOTOkd7LdWnk=";
      }) {};
      # dontCheck, tests fail
      http2 = haskell.lib.dontCheck (self.callCabal2nix "http2" (fetchFromGitHub {
        owner = "kazu-yamamoto";
        repo = "http2";
        rev = "b5a1b7200cf5bc7044af34ba325284271f6dff25";
        sha256 = "sha256-6zubMhgzsCTKXMht+Pbfoc1OPtvFMUycJcaqUyQoCzc=";
      }) {});
      # dontCheck, tests fail
      sqlcipher-simple = haskell.lib.dontCheck (self.callCabal2nix "sqlcipher-simple" (fetchFromGitHub {
        owner = "simplex-chat";
        repo = "sqlcipher-simple";
        rev = "5e154a2aeccc33ead6c243ec07195ab673137221";
        sha256 = "sha256-oAK4Hl+3arynrhWtc49PbfOlQ69aqgAQeHiTrnhhL7Q=";
      }) {});

      ini = self.callHackageDirect {
        pkg = "ini";
        ver = "0.4.1";
        sha256 = "sha256-J1aUHE37ygFTqt/6sHJSrij7fFKx+lttHZsg97LGwyY=";
      } {};
      hspec = self.callHackageDirect {
        pkg = "hspec";
        ver = "2.7.10";
        sha256 = "sha256-g81g8A+AiZcdEFz2eUFW5IuS7E3dXGrZoSBKHCBQGqE=";
      } {};
      hspec-core = self.callHackageDirect {
        pkg = "hspec-core";
        ver = "2.7.10";
        sha256 = "sha256-3CdA+cweNIq2vGz5OZvajYAcH5160AKldPWGGuL94Ng=";
      } {};
      hspec-discover = self.callHackageDirect {
        pkg = "hspec-discover";
        ver = "2.7.10";
        sha256 = "sha256-fwYgMFx0tE0S0+DhLadkigDytYSlUxxE3zgO+eOeQE4=";
      } {};
      tls = self.callHackageDirect {
        pkg = "tls";
        ver = "1.6.0";
        sha256 = "sha256-XkYW2Zbp0FOTELPFJqic6PdXOvroGbiZ7UPd3lfxg68=";
      } {};
      generic-random = self.callHackageDirect {
        pkg = "generic-random";
        ver = "1.4.0.0";
        sha256 = "sha256-d43zNJB7LqYNgIoPPQ4RgZqHjt6LGD6lek6OAmDO8/E=";
      } {};
      memory = self.callHackageDirect {
        pkg = "memory";
        ver = "0.15.0";
        sha256 = "sha256-mz3oD7somGlxfZDUc/72TQ/6wEvFRNtntX01YYos5Bw=";
      } {};
    };
  };
  libDeps = with hp; [
    QuickCheck composition constraints containers cryptonite cryptostore
    data-default direct-sqlcipher directory filepath generic-random
    http-types http2 ini iproute iso8601-time memory mtl network
    network-transport optparse-applicative process random simple-logger
    socks sqlcipher-simple stm template-haskell temporary text time
    time-compat time-manager tls transformers unliftio unliftio-core
    websockets x509 x509-store x509-validation yaml
  ];
  execDeps = libDeps ++ (with hp; [
    aeson ansi-terminal asn1-encoding asn1-types async attoparsec base
    base64-bytestring bytestring case-insensitive
  ]);
  testDeps = execDeps ++ (with hp; [
    HUnit deepseq hspec hspec-core main-tester silently timeit
  ]);
in
hp.mkDerivation {
  pname = "simplexmq";
  version = "stable-6c6f2205-git";

  src = fetchFromGitHub {
    owner = "simplex-chat";
    repo = "simplexmq";
    rev = "6c6f22051d693e00aaa4c4e6c5b6bff7e9a40b36";
    sha256 = "sha256-lVITTQCKAGcGLrZUCC8JSO2o/KCSdqS+4aLSWbS4JFY=";
  };

  patches = [ ./config-env-vars.patch ];

  isLibrary = true;
  isExecutable = true;

  libraryHaskellDepends = libDeps;
  executableHaskellDepends = execDeps;
  testHaskellDepends = testDeps;

  homepage = "https://github.com/simplex-chat/simplexmq";
  description = "SimpleXMQ - A reference implementation of the SimpleX Messaging Protocol for simplex queues over public networks";
  license = lib.licenses.agpl3Only;

  doCheck = false;              # tests hang
}
