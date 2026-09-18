# Config manager

![](./images/config-manager-install.png)

> [!WARNING]
> These are **my** personal configurations. Maybe it will not work on your environment.

This is my tools config manager. It provides configuration for:

- Tmux
- Tmuxer (my tmux session setup tool, built from source)
- Mark (my markdown viewer, registered as the default `.md` handler)
- Alacritty (default terminal: GNOME, COSMIC, x-terminal-emulator and xdg default apps)
- Helix (default editor, every vim/neovim package is removed)
- Git config
- Bash
- Kubectl
- Nim
- Go
- Rust
- .NET
- C and family (clang, gcc, make, etc)

If you want to see every single command that this tool will run on your machine
during the installation process, you can view [this file](./commands/install-pipeline.go).

## Ignoring steps

Every step belongs to one or more groups. Use `-ignore` to skip them:

```bash
sudo config-manager install -ignore desktop,dotnet
```

Run `config-manager help` to list the groups. Dependencies are not resolved: ignoring `cargo` will break `helix` and `alacritty`.

## Desktop (GNOME)

The `desktop` group applies my GNOME preferences:

- Alt+Tab / Super+Tab only show what is in the current workspace
- Workspaces span every monitor (not only the primary one)
- The dock only shows apps from the current workspace
- Alt+Tab switches windows, Super+Tab switches applications
- Alacritty as the default terminal

## Configs

The files inside [configs](./configs) are **symlinked** into your home (`~/.bashrc`, `~/.gitconfig`, `~/.tmux.conf`,
`~/.config/alacritty`, `~/.config/helix/*.toml`), so editing them on the system edits the repository.

If a regular file/folder already exists in the destination, it is moved to `<name>.bak.<timestamp>` first.

The repository is expected at `~/.config-manager`. Use `CONFIG_MANAGER_DIR` to point somewhere else:

```bash
sudo CONFIG_MANAGER_DIR=$PWD config-manager install
```

Machine-specific or sensitive settings (passwords, work paths, `KUBECONFIG`, ...) must go in `~/.bashrc.local`,
which is sourced by `.bashrc` and is **not** versioned.

## Installing the tool

```bash
git clone https://github.com/marcos-venicius/config-manager.git ~/.config-manager && go install github.com/marcos-venicius/config-manager
```

## Testing during development

Since I don't want you to break your system just to test this tool, you can execute this via docker.

You just need to have `docker` and `make` installed on your machine.

Then, run `make`.

This command will install and configure all the tools inside a docker container and you will seed all the logs during
the process.

Once you did that, you can clean up the room by running `make clean`.

## Tasks

- Wodo (later)
