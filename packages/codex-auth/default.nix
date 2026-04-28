{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
}:
let
  version = "0.2.7";
  sources = {
    "aarch64-darwin" = {
      url = "https://github.com/Loongphy/codex-auth/releases/download/v${version}/codex-auth-macOS-ARM64.tar.gz";
      sha256 = "1flciys9qjd7235ykby6s3ryz00idakj8fi773md5ljdl6wd01g1";
    };
    "x86_64-darwin" = {
      url = "https://github.com/Loongphy/codex-auth/releases/download/v${version}/codex-auth-macOS-X64.tar.gz";
      sha256 = "0x1lhh25dpf932z4whd5vz5fbnicinxhqkwswy45fqghxzh7g73q";
    };
    "aarch64-linux" = {
      url = "https://github.com/Loongphy/codex-auth/releases/download/v${version}/codex-auth-Linux-ARM64.tar.gz";
      sha256 = "1kssxd09phs09f3k1i6iir6l3i12k6v5qqcvm7mxfj2phlsnv90d";
    };
    "x86_64-linux" = {
      url = "https://github.com/Loongphy/codex-auth/releases/download/v${version}/codex-auth-Linux-X64.tar.gz";
      sha256 = "06sba8w68y2fmvmyiaxzh6ff04ivb92fq0rqycisj7zi3rdvg7wv";
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
