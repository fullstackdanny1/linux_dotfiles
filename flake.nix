{
  description = "Sway dotfiles: main (elegant, yet minimal) și second (barebones but with style)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      stylix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Schimbă aici dacă userul diferă pe laptopuri.
      user = {
        name = "andrew123";
        home = "/home/andrew123";
      };

      mkHome =
        hostModule:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit user;
            theme = import ./home/theme.nix;
            icons = import ./home/icons.nix;
          };
          modules = [
            stylix.homeModules.stylix
            ./home/common.nix
            ./home/sway-common.nix
            hostModule
          ];
        };
    in
    {
      homeConfigurations = {
        main = mkHome ./home/main.nix;
        second = mkHome ./home/second.nix;
      };

      # Fișierele de sistem (greetd, greeter, wrapper-ul de sesiune), randate cu
      # aceeași paletă. Le instalează `./install.sh <host> system`.
      packages.${system} = {
        system-main = import ./system {
          inherit pkgs;
          host = "main";
        };
        system-second = import ./system {
          inherit pkgs;
          host = "second";
        };
        default = home-manager.packages.${system}.default;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
