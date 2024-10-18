{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    crane.url = "github:ipetkov/crane";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-analyzer-src.follows = "";
    };
  };

  outputs = { self, nixpkgs, crane, fenix }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      craneLib = (crane.mkLib pkgs).overrideToolchain
        fenix.packages.${system}.stable.toolchain;

      src = pkgs.lib.cleanSourceWith {
        src = ./.;

        filter = path: type:
          (craneLib.filterCargoSources path type)
        ;
      };

      commonArgs = {
        inherit src;
        version = "0.1.0";
        strictDeps = true;
        pname = "webecho";
        name = "webecho";
        buildInputs = [ ];
        nativeBuildInputs = [ ];
      };

      cargoArtifacts = craneLib.buildDepsOnly commonArgs;

      webecho = craneLib.buildPackage (commonArgs // {
        inherit cargoArtifacts;
        doCheck = false;
        CARGO_PROFILE = "release";
      });

      webechoImg = pkgs.dockerTools.streamLayeredImage {
        name = "webecho";
        tag = "latest";
        contents = [self.packages.${system}.webecho];

        config = {
          Cmd = [ "/bin/webecho" ];
        };
      };
    in
    {
      packages.${system} = { inherit webecho; inherit webechoImg; };

      devShells.${system}.default = craneLib.devShell {
        packages = with pkgs; [ nixpkgs-fmt nil dive flyctl ];
      };
    };
}
