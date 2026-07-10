{
  description = "Reusable NixOS base configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      overlay = final: prev: {
        nvchad = inputs.nix4nvchad.packages.${final.stdenv.hostPlatform.system}.nvchad;
      };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlay ];
      };
    in
    {
      nixosConfigurations.nix01 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/nix01
          inputs.home-manager.nixosModules.default
          { nixpkgs.overlays = [ overlay ]; }
        ];
      };
      nixosConfigurations.iris = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/iris
          inputs.home-manager.nixosModules.default
          { nixpkgs.overlays = [ overlay ]; }
        ];
      };
      homeConfigurations = import ./home/users.nix {
        inherit pkgs home-manager;
      };
    };
}
