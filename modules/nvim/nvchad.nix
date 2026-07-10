{ pkgs, ... }:

{
  # nvchad (nix4nvchad) ships bin/nvim: a wrapper that seeds ~/.config/nvim
  # from the NvChad starter on first launch, then runs neovim against it.
  environment.systemPackages = with pkgs; [
    nvchad
    # LSP servers and formatters for nvim
    nixd
    nixfmt
    bash-language-server
    python3Packages.flake8
  ];

  environment.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };
}
