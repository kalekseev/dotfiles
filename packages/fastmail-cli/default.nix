{
  buildGoModule,
  lib,
}:

buildGoModule rec {
  pname = "fastmail-cli";
  version = "0.1.0";

  src = ./src;

  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  doCheck = true;

  postInstall = ''
    mv "$out/bin/fastmail-cli" "$out/bin/fastmail"
  '';

  meta = {
    description = "Constrained Fastmail CLI backed by macOS Keychain";
    homepage = "https://github.com/kalekseev/dotfiles";
    license = lib.licenses.mit;
    mainProgram = "fastmail";
    platforms = lib.platforms.darwin;
  };
}
