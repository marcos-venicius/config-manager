# Config manager

> [!WARNING]
> These are **my** personal configurations. Maybe it will not work on your environment.

This is my tools config manager. It provides configuration for:

- Tmux
- Alacritty
- Zsh (oh-my-zsh)
- Vim
- Neovim
- Git config

## Installing

**Requirements:**

1. Have golang installed

```bash
git clone https://github.com/marcos-venicius/config-manager.git ~/.config-manager && go install github.com/marcos-venicius/config-manager
```

If you want to put the repository in a different location, you can just add a new env var called `CM_APP_FOLDER_LOCATION` with the path to the custom location.

