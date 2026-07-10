{
  pkgs,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    nvchad
    # Optional: runtime LSP servers, formatters
    nixd
    nixpkgs-fmt
    bash-language-server
    python3Packages.flake8
  ];
}
