{ config, pkgs, ... }:

{
  home.username = "frieser";
  home.homeDirectory = "/var/home/frieser";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      lra = "/var/home/frieser/Documents/work/bbva/lra/lra_cli/build/bin/lra";
      vim = "nvim";
      k = "kubectl";
      bazel = "bazelisk";
      ll = "ls -l";
      update = "sudo nixos-rebuild switch";
      vpn = "(docker rm -f bbva-vpn & sleep 3 && cd /var/home/frieser/Documents/work/bbva/tools/bbva-vpn/ && ./start-vpn.sh /forticlient/fortivpn.sh)";
      proxy = "(cd /var/home/frieser/Documents/work/bbva/tools/bbva-vpn/ && sshuttle -NHr root@localhost:30022 10.48.0.0/16 10.50.0.0/16 10.51.0.0/16 10.52.0.0/16 10.111.0.0/16 22.0.0.0/8 23.1.2.0/24 23.1.176.0/24 23.2.2.0/24 23.4.0.0/16 100.64.0.0/10 --ssh-cmd \'ssh -o StrictHostKeyChecking=no -i podman-data/id_rsa\' --no-latency-control --ns-hosts 10.51.33.33 --to-ns 10.51.33.33)";
    };
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
    zplug = {
      enable = true;
      plugins = [
        { name = "jeffreytse/zsh-vi-mode"; }
        { name = "mafredri/zsh-async"; }
        { name = "sindresorhus/pure"; tags = [use:pure.zsh as:theme]; }
        { name = "zsh-users/zsh-history-substring-search"; }
        { name = "rupa/z"; }
        { name = "zsh-users/zsh-completions"; } # Proporciona completados adicionales para una amplia gama de herramientas y comandos.
        { name = "MichaelAquilina/zsh-you-should-use"; } # Sugiere alias definidos para comandos escritos en la terminal.
        { name = "Aloxaf/fzf-tab"; } # Mejora el autocompletado de Zsh con una interfaz de búsqueda difusa utilizando fzf.
{ name = "plugins/sudo"; tags = [ from:oh-my-zsh ]; }
{ name = "plugins/web-search"; tags = [ from:oh-my-zsh ]; }
{ name = "plugins/docker"; tags = [ from:oh-my-zsh ]; } # Completado para comandos de Docker.
{ name = "plugins/kubectl"; tags = [ from:oh-my-zsh ]; } # Completado para comandos de Kubernetes (kubectl).
{ name = "plugins/aws"; tags = [ from:oh-my-zsh ]; } # Completado para comandos de AWS CLI.
{ name = "plugins/npm"; tags = [ from:oh-my-zsh ]; } # Completado para comandos de npm (Node Package Manager).
{ name = "plugins/pip"; tags = [ from:oh-my-zsh ]; } # Completado para comandos de pip (Python Package Installer).
{ name = "plugins/terraform"; tags = [ from:oh-my-zsh ]; } # Completado para comandos de Terraform (Infraestructura como Código).
{ name = "plugins/ssh"; tags = [ from:oh-my-zsh ]; } # Completado para comandos y configuraciones de SSH.
{ name = "plugins/systemd"; tags = [ from:oh-my-zsh ]; } # Completado para comandos de systemd (Gestor de servicios en Linux).
{ name = "plugins/podman"; tags = [ from:oh-my-zsh ]; } # Completado para comandos de Podman.
{ name = "plugins/git"; tags = [ from:oh-my-zsh ]; } # Alias y funciones útiles para comandos de Git.
{ name = "plugins/git-extras"; tags = [ from:oh-my-zsh ]; } # Comandos adicionales para mejorar la experiencia con Git.
{ name = "plugins/git-lfs"; tags = [ from:oh-my-zsh ]; } # Completado y alias para Git Large File Storage (LFS).
{ name = "plugins/gitfast"; tags = [ from:oh-my-zsh ]; } # Completado más rápido para comandos de Git.
{ name = "plugins/kubectx"; tags = [ from:oh-my-zsh ]; } # Autocompletado y alias para kubectx y kubens.

      ];
    };
  };

  home.sessionVariables = {
    EDITOR = "vim";
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "/usr/local/go/bin"
    "$HOME/go/bin"
    "$HOME/.npm-packages/bin"
  ];

  programs.home-manager.enable = true;
}
