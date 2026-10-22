{
  description = "n4r77 setup v2.1.0: sway, swaylock, swaybar + i3status-rust, workflow de dev cu helix + tmux";

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

      n4r77 = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit user;
          theme = import ./home/theme.nix;
          icons = import ./home/icons.nix;
        };
        modules = [
          stylix.homeModules.stylix
          ./home/common.nix
          ./home/sway.nix
          ./home/bar.nix
          ./home/dev.nix
        ];
      };
    in
    {
      homeConfigurations = { inherit n4r77; };

      # Fișierele de sistem (greetd + tuigreet, wrapper-ul de sesiune). Le instalează
      # `./install.sh`.
      packages.${system} = {
        system-files = import ./system { inherit pkgs; };
        default = home-manager.packages.${system}.default;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
