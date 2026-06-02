{
  stdenv,
  lib,
  darwin,
  fetchFromGitHub,
  fetchurl,
  fetchPnpmDeps,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
}:
let
  pnpm = pnpm_10.override { inherit nodejs; };

  platforms = {
    "aarch64-darwin" = {
      fossilize = "darwin-arm64";
      binary = "sentry-darwin-arm64";
    };
    "x86_64-darwin" = {
      fossilize = "darwin-x64";
      binary = "sentry-darwin-x64";
    };
    "aarch64-linux" = {
      fossilize = "linux-arm64";
      binary = "sentry-linux-arm64";
    };
    "x86_64-linux" = {
      fossilize = "linux-x64";
      binary = "sentry-linux-x64";
    };
  };

  platform =
    platforms.${stdenv.hostPlatform.system}
      or (throw "unsupported system: ${stdenv.hostPlatform.system}");

  sentryApiSchema = fetchurl {
    url = "https://raw.githubusercontent.com/getsentry/sentry-api-schema/0.141.0/openapi-derefed.json";
    hash = "sha256-GjGMWxTRVora4p2EwizEpvdcKbIbXHpn1/+fyKeCO+4=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "sentry";
  version = "0.35.0";

  src = fetchFromGitHub {
    owner = "getsentry";
    repo = "cli";
    tag = finalAttrs.version;
    hash = "sha256-CpQyzvD7aMJWS8a0piwHLEdjl8rUF2XbiGo5yP/enK4=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 3;
    hash = "sha256-ZOg6Sgepzk/9xEf+EZLKN8GpYCAoQ9e8RMuMYrg+X6M=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.sigtool
  ];

  postPatch = ''
    substituteInPlace script/build.ts \
      --replace-fail 'const NODE_VERSION = "lts";' 'const NODE_VERSION = "${nodejs.version}";'

    substituteInPlace script/generate-api-schema.ts \
      --replace-fail \
        'const openApiUrl = await getOpenApiUrl();
console.log(`Fetching OpenAPI spec from ''${openApiUrl}...`);
const response = await fetch(openApiUrl);
if (!response.ok) {
  throw new Error(
    `Failed to fetch OpenAPI spec: ''${response.status} ''${response.statusText}`
  );
}
const spec = (await response.json()) as OpenApiSpec;' \
        'const openApiUrl = "${sentryApiSchema}";
console.log(`Reading OpenAPI spec from ''${openApiUrl}...`);
const spec = JSON.parse(await readFile(openApiUrl, "utf-8")) as OpenApiSpec;'
  '';

  env = {
    # Public sentry.io OAuth app client ID from src/lib/oauth.ts.
    SENTRY_CLIENT_ID = "1d673b81d60ef84c951359c36296972ca6fd41bd8f45acd2d3a783a3b3c28e41";
    UV_USE_IO_URING = "0";
  };

  preBuild = ''
    export FOSSILIZE_CACHE_DIR="$PWD/.node-cache"
    mkdir -p "$FOSSILIZE_CACHE_DIR"
    cp ${lib.getExe nodejs} "$FOSSILIZE_CACHE_DIR/node-v${nodejs.version}-${platform.fossilize}"
    chmod u+w "$FOSSILIZE_CACHE_DIR/node-v${nodejs.version}-${platform.fossilize}"
  '';

  buildPhase = ''
    runHook preBuild

    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 dist-bin/${platform.binary} $out/bin/sentry

    runHook postInstall
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isDarwin ''
    codesign --force --sign - $out/bin/sentry
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck

    export HOME="$TMPDIR/sentry-home"
    mkdir -p "$HOME"

    version="$($out/bin/sentry --version)"
    test "$version" = "${finalAttrs.version}"

    runHook postInstallCheck
  '';

  meta = {
    description = "Sentry CLI from getsentry/cli";
    homepage = "https://github.com/getsentry/cli";
    license = lib.licenses.fsl11Asl20;
    platforms = builtins.attrNames platforms;
    mainProgram = "sentry";
  };
})
