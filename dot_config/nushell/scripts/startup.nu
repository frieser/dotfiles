
# Install tpm if not installed
if not ($nu.home-path | path join ".config/tmux/plugins/tpm" | path exists) {
    ^git clone https://github.com/tmux-plugins/tpm ($nu.home-path | path join ".config/tmux/plugins/tpm")
    # si quisieras ejecutar el install_plugins también:
    # ^TMUX_PLUGIN_MANAGER_PATH=($nu.home-path | path join ".config/tmux/plugins") \
      ^($nu.home-path | path join ".config/tmux/plugins/tpm/bin/install_plugins")
}
