self: super: {
  overmind = super.overmind.overrideAttrs (old: rec {
    version = "2.1.1";
    goPackagePath = "github.com/kalekseev/overmind";

    src = super.fetchFromGitHub {
      owner = "kalekseev";
      repo = "overmind";
      rev = "5aeef02ebe7b7d15d3e61199124c88c125fa4a7f";
      sha256 = "1zjanjk9vy96h2lx2v0b1ga81df603vmqfr4ar0c3whwkx3kzfvp";
    };

    prePatch = ''
      substituteInPlace  main.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  cmd_run.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  cmd_kill.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  cmd_echo.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  cmd_restart.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  start/process.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  start/procfile.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  start/multi_output.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  start/port.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  start/command.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  start/command_center.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  start/handler.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  start/tmux.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  cmd_connect.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  go.mod --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  cmd_quit.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
      substituteInPlace  cmd_stop.go --replace 'DarthSim/overmind' 'kalekseev/overmind'
    '';
  });
}
