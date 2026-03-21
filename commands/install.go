package commands

import (
	"fmt"
	"os"

	"github.com/marcos-venicius/config-manager/utils"
)

type step_t struct {
	label string
	commands []string
	healthCheckCommands []string
}

var installationSteps = []step_t{
	{
		label: "APT GET Update",
		commands: []string{
			"apt-get update -y",
			"apt-get upgrade -y",
		},
	},
	{
		label: "Install add-apt-repository",
		commands: []string{
			"apt-get install software-properties-common -y",
		},
		healthCheckCommands: []string{
			"add-apt-repository --help",
		},
	},
	{
		label: "Curl + Wget",
		commands: []string{
			"apt-get install curl -y",
			"apt-get install wget -y",
		},
		healthCheckCommands: []string{
			"wget --version",
			"curl --version",
		},
	},
	{
		label: "Build Essentials",
		commands: []string{
			"apt-get install build-essential -y",
		},
		healthCheckCommands: []string{
			"gcc --version",
			"make --version",
		},
	},
	{
		label: "Install CLang",
		commands: []string{
			"apt-get install clang -y",
		},
		healthCheckCommands: []string{
			"clang --version",
		},
	},
	{
		label: "Ripgrep",
		commands: []string{
			"apt-get install ripgrep -y",
		},
		healthCheckCommands: []string{
			"rg --version",
		},
	},
	{
		label: "XClip",
		commands: []string{
			"apt-get install xclip -y",
		},
		healthCheckCommands: []string{
			"xclip -version",
		},
	},
	{
		label: "GIT",
		commands: []string{
			"add-apt-repository ppa:git-core/ppa -y",
			"apt-get update -y",
			"apt-get install git -y",
		},
		healthCheckCommands: []string{
			"git --version",
		},
	},
	{
		label: "Cargo",
		commands: []string{
			"curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rustc.sh",
			"chmod u+x /tmp/rustc.sh",
			"/tmp/rustc.sh -y",
		},
		healthCheckCommands: []string{
			"$HOME/.cargo/bin/cargo --version",
		},
	},
	{
		label: "Tmux",
		commands: []string{
			"apt-get install tmux -y",
		},
		healthCheckCommands: []string{
			"which tmux",
		},
	},
	{
		label: "Neovim",
		commands: []string{
			"mkdir -p /tmp/neovim-installation",
			// TODO: Do I need to install wget?
			"wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -O /tmp/neovim-installation/file.tar.gz",
			// TODO: Do I need to install tar?
			"tar -xvf /tmp/neovim-installation/file.tar.gz -C /tmp/neovim-installation/",
			"mkdir -p /tmp",
			"mkdir -p /opt",
			"mv /tmp/neovim-installation/nvim-linux-x86_64 /opt/nvim",
			"mv /opt/nvim/bin/nvim /opt/nvim/bin/vi",
			"ln -s /opt/nvim/bin/vi /usr/local/bin/vi",
			"rm -rf /tmp/neovim-installation",
		},
		healthCheckCommands: []string{
			"vi --version",
		},
	},
	{
		label: "Gnome configs",
		commands: []string{
			"gsettings set org.gnome.shell.app-switcher current-workspace-only true",
		},
		healthCheckCommands: []string{},
	},
	{
		// alacritty installation is too slow, keep it at the end
		// alacritty installation dependency
		label: "Font config",
		commands: []string{
			"apt-get install libfontconfig1-dev -y",
		},
	},
	{
		label: "Alacritty",
		commands: []string{
			"$HOME/.cargo/bin/cargo install alacritty",
		},
		healthCheckCommands: []string{
			"$HOME/.cargo/bin/alacritty --version",
		},
	},
}

func Install() error {
	for stepIndex, step := range(installationSteps) {
		if stepIndex > 0 {
			fmt.Println()
		}

		fmt.Printf("\033[0;34mStep %02d: %s\033[0m\n", stepIndex + 1, step.label)

		// TODO: check healthCheckCommands before, so we can skip in case all of them succeed
		for _, cmd := range(step.commands) {
			fmt.Printf("  \033[0;33m$\033[0m %s\n", cmd);

			exitCode := utils.SysExec(cmd, "    ")

			if exitCode == 0 {
				fmt.Println("    \033[0;32m[SUCCESS]\033[0m")
			} else {
				fmt.Printf("    \033[0;31m[FAIL]: %d\033[0m", exitCode)

				if len(step.healthCheckCommands) > 0 {
					fmt.Println()
					fmt.Printf("\n\ninstallation pipeline faild: step %02d (%s) failed with exit code %d for \"%s\"\n\n", stepIndex, step.label, exitCode, cmd)
					os.Exit(1)
				} else {
					fmt.Println("  ignoring...")
				}
			}
		}

		fmt.Println()

		if len(step.healthCheckCommands) > 0 {
			fmt.Printf("\033[0;36m  Health checking...\033[0m\n")

			for j, healthCmd := range(step.healthCheckCommands) {
				fmt.Printf("    Checking %02d: %s...", j + 1, healthCmd)

				exitCode := utils.SimpleExec(healthCmd)

				if exitCode == 0 {
					fmt.Println(" \033[1;32m[OK]\033[0m")
				} else {
					fmt.Printf(" \033[1;31m[FAIL]: %d\033[0m\n", exitCode)

					fmt.Printf("\n\ninstallation pipeline faild during helth check: step %02d (%s) failed with exit code %d while health checking \"%s\"\n\n", stepIndex, step.label, exitCode, healthCmd)
					os.Exit(1)
				}
			}
		} else {
			fmt.Printf("\033[0;36m  No health check...\033[0m\n")
		}
	}

	return nil
}
