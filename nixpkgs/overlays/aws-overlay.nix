self: super:
rec {
  python = with super; super.python3.override {
    packageOverrides = self: super: {
      botocore = super.botocore.overridePythonAttrs (oldAttrs: rec {
        version = "2.0.0dev27";
        src = fetchFromGitHub {
          owner = "boto";
          repo = "botocore";
          rev = "ada86382227e5d329fefaaf96fe735260daa0d5b";
          sha256 = "1rfw5mc0fgb2spmy917bd4a28h4x1kd0kgp3pm9lg086xfqjd3br";
        };
      });
      prompt_toolkit = super.prompt_toolkit.overridePythonAttrs (oldAttrs: rec {
        version = "2.0.10";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "1nr990i4b04rnlw1ghd0xmgvvvhih698mb6lb6jylr76cs7zcnpi";
        };
      });
    };
  };

  pythonPackages = python.pkgs;

  awscli = with self; pythonPackages.buildPythonApplication rec {
    pname = "awscli";
    version = "2.0.23"; # N.B: if you change this, change botocore to a matching version too

    src = fetchFromGitHub {
      owner = "aws";
      repo = "aws-cli";
      rev = version;
      sha256 = "1njdn8q8pvj8ybz67m6zskmixmmzl8agaqs1irr4ap072yc03y6w";
    };

    postPatch = ''
      substituteInPlace setup.py --replace ",<0.16" ""
      substituteInPlace setup.py --replace "cryptography>=2.8.0,<=2.9.0" "cryptography>=2.8.0,<2.10"
    '';

    # No tests included
    doCheck = false;

    propagatedBuildInputs = with pythonPackages; [
      botocore
      colorama
      docutils
      cryptography
      s3transfer
      ruamel_yaml
      wcwidth
      prompt_toolkit
    ];

    postInstall = ''
      mkdir -p $out/etc/bash_completion.d
      echo "complete -C $out/bin/aws_completer aws" > $out/etc/bash_completion.d/awscli
      mkdir -p $out/share/zsh/site-functions
      mv $out/bin/aws_zsh_completer.sh $out/share/zsh/site-functions
      rm $out/bin/aws.cmd
    '';

    passthru.python = python; # for aws_shell

    meta = with super.lib; {
      homepage = "https://aws.amazon.com/cli/";
      description = "Unified tool to manage your AWS services";
      license = licenses.asl20;
      maintainers = [ ];
    };
  };
}
