{
  #nix build .#mx
  description = "Home Manager configurations";

  inputs = {
    nixpkgs.url = "flake:nixpkgs";
    homeManager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, homeManager, flake-utils }: {
    homeConfigurations = {
      base = name: homeManager.lib.homeManagerConfiguration {
        configuration = import ./home.nix;

        system = "x86_64-linux";
        homeDirectory = "/home/${name}";
        username = "${name}";
        stateVersion = "21.11";
      };
    };
    packages.x86_64-linux = {
      mx = (self.homeConfigurations.base "mx").activationPackage;
      ubuntu = (self.homeConfigurations.base "ubuntu").activationPackage;
    };
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.mx;
  };
}
