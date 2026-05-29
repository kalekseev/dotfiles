{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
}:
let
  version = "0.2.9";
  sources = {
    "aarch64-darwin" = {
      url = "https://github.com/Loongphy/codex-auth/releases/download/v${version}/codex-auth-macOS-ARM64.tar.gz";
      sha256 = "0b5l0zif9qp6vs8pdsv55pryf0mg04bhbn3zngsjwn65kp2lg86b";
    };
    "x86_64-darwin" = {
      url = "https://github.com/Loongphy/codex-auth/releases/download/v${version}/codex-auth-macOS-X64.tar.gz";
      sha256 = "07763gxdhcb218cn74a65c2h2ap6g0w2a1fiq4n43v9dzpjg5bkc";
    };
    "aarch64-linux" = {
      url = "https://github.com/Loongphy/codex-auth/releases/download/v${version}/codex-auth-Linux-ARM64.tar.gz";
      sha256 = "0jnzwka5bjnip49g34jlhjq6c6y240kvj2shi4zc6i6gsi0fyiww";
    };
    "x86_64-linux" = {
      url = "https://github.com/Loongphy/codex-auth/releases/download/v${version}/codex-auth-Linux-X64.tar.gz";
      sha256 = "07swhfslxh3d6qz42i6z82mwlh31r5i08c8clcxcksr260y90k89";
    };
  };
  src = fetchurl sources.${stdenv.hostPlatform.system} or (throw "unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "codex-auth";
  inherit version src;

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 codex-auth $out/bin/codex-auth
    runHook postInstall
  '';

  meta = {
    description = "codex-auth binary from Loongphy/codex-auth";
    homepage = "https://github.com/Loongphy/codex-auth";
    platforms = builtins.attrNames sources;
    mainProgram = "codex-auth";
  };
}
