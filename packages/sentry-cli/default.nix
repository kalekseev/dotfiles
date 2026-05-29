{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
}:
let
  version = "0.34.0";
  sources = {
    "aarch64-darwin" = {
      url = "https://github.com/getsentry/cli/releases/download/${version}/sentry-darwin-arm64";
      sha256 = "1hvnnin5p0zd1d4dasackjqmbjg17kix7v2hsbqwqs36027sr4zz";
    };
    "x86_64-darwin" = {
      url = "https://github.com/getsentry/cli/releases/download/${version}/sentry-darwin-x64";
      sha256 = "1yn199pd36ap4nf10hmrifa5xcgnh94lshi0n9njxlv95f1nxfac";
    };
    "aarch64-linux" = {
      url = "https://github.com/getsentry/cli/releases/download/${version}/sentry-linux-arm64";
      sha256 = "1v1l2daqyhgx26ckpj04ilhxyb1dy67manylj5dbji9anv0z9wxs";
    };
    "x86_64-linux" = {
      url = "https://github.com/getsentry/cli/releases/download/${version}/sentry-linux-x64";
      sha256 = "1d895hzdj9np83afrqscll7yp5d4g13afsvjiq70w2c7z4bwk121";
    };
  };
  src = fetchurl sources.${stdenv.hostPlatform.system} or (throw "unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "sentry-cli";
  inherit version src;

  dontUnpack = true;
  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/sentry
    runHook postInstall
  '';

  meta = {
    description = "Sentry CLI binary from getsentry/cli";
    homepage = "https://github.com/getsentry/cli";
    platforms = builtins.attrNames sources;
    mainProgram = "sentry";
  };
}
