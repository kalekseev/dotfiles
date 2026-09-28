{
  buildGoModule,
  lib,
  libsecret,
  makeWrapper,
  stdenv,
}:

buildGoModule rec {
  pname = "fastmail-cli";
  version = "0.2.0";

  src = ./src;

  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  doCheck = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ makeWrapper ];

  postInstall = ''
    mv "$out/bin/fastmail-cli" "$out/bin/fastmail"
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    wrapProgram "$out/bin/fastmail" \
      --prefix PATH : ${lib.makeBinPath [ libsecret ]}
  '';

  meta = {
    description = "Constrained Fastmail CLI backed by the system credential store";
    homepage = "https://github.com/kalekseev/dotfiles";
    license = lib.licenses.mit;
    mainProgram = "fastmail";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}
