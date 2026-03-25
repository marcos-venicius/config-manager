package commands

import (
	"fmt"
	"os"

	"github.com/marcos-venicius/config-manager/sys"
)

type step_t struct {
	label               string
	asHome              bool // do not run commands as sudo
	commands            []string
	healthCheckCommands []string
}

func Install() {
	baseCmd := sys.Command()

	for stepIndex, step := range installationSteps {
		if stepIndex > 0 {
			fmt.Println()
		}

		fmt.Printf("\033[0;34mStep %02d: %s\033[0m\n", stepIndex+1, step.label)

		if len(step.healthCheckCommands) > 0 {
			for _, healthCmd := range step.healthCheckCommands {
				exitCode := baseCmd.RunAsHome(healthCmd, nil, nil)

				if exitCode != 0 {
					goto install_step_tools
				}
			}

			fmt.Println()
			fmt.Printf("  \033[0;36mHealth checks:\033[0m\n\n")

			for _, healthCmd := range step.healthCheckCommands {
				fmt.Printf("    \033[0;33m$\033[0m %s\n", healthCmd)
				fmt.Printf("      \033[1;32mok\033[0m\n")
			}

			fmt.Println()
			fmt.Printf("  \033[0;36mSkipping step %02d (%s). already installed...\033[0m\n", stepIndex+1, step.label)
			continue
		}

	install_step_tools:
		for i, cmd := range step.commands {
			if i > 0 {
				fmt.Println()
			}

			fmt.Printf("  \033[0;33m$\033[0m %s\n", cmd)

			exitCode := 0

			if step.asHome {
				exitCode = baseCmd.RunAsHome(cmd, stdoutStderrPrinter("    "), stdoutStderrPrinter("    "))
			} else {
				exitCode = baseCmd.RunAsSudo(cmd, stdoutStderrPrinter("    "), stdoutStderrPrinter("    "))
			}

			if exitCode == 0 {
				fmt.Println("    \033[0;32mok\033[0m")
			} else {
				fmt.Printf("    \033[0;31mfail: %d\033[0m", exitCode)

				if len(step.healthCheckCommands) > 0 {
					fmt.Println()
					fmt.Printf("\n\ninstallation pipeline faild: step %02d (%s) failed with exit code %d for '%s'\n\n", stepIndex+1, step.label, exitCode, cmd)
					os.Exit(1)
				} else {
					fmt.Println("  ignoring...")
				}
			}
		}

		fmt.Println()

		if len(step.healthCheckCommands) > 0 {
			fmt.Printf("\033[0;36m  Health checking...\033[0m\n")

			for _, healthCmd := range step.healthCheckCommands {
				fmt.Printf("    \033[0;33m$\033[0m %s\n", healthCmd)

				exitCode := baseCmd.RunAsHome(healthCmd, nil, nil)

				if exitCode == 0 {
					fmt.Println("      \033[1;32mok\033[0m")
				} else {
					fmt.Printf("      \033[1;31mfail: %d\033[0m\n", exitCode)

					fmt.Printf("\n\ninstallation pipeline faild during helth check: step %02d (%s) failed with exit code %d while health checking '%s'\n\n", stepIndex+1, step.label, exitCode, healthCmd)
					os.Exit(1)
				}
			}
		} else {
			fmt.Printf("\033[0;36m  No health checks...\033[0m\n")
		}
	}
}

func stdoutStderrPrinter(padding string) *func(string) {
	printer := func(text string) {
		fmt.Printf("\033[2;38m%s%s\033[0m\n", padding, text)
	}

	return &printer
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
		label:  "Cargo",
		asHome: true,
		commands: []string{
			"curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rustc.sh",
			"chmod u+x /tmp/rustc.sh",
			"/tmp/rustc.sh -y",
			"rm -rf /tmp/rustc.sh",
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
		label:  "Dotnet",
		asHome: true,
		commands: []string{
			"mkdir -p $HOME/tools/dotnet",
			"wget https://dot.net/v1/dotnet-install.sh -O $HOME/tools/dotnet/dotnet-install.sh",
			"chmod u+x $HOME/tools/dotnet/dotnet-install.sh",
			// Installing version 9.0
			"$HOME/tools/dotnet/dotnet-install.sh --channel 9.0",
		},
		healthCheckCommands: []string{
			"$HOME/.dotnet/dotnet --list-sdks | grep -qPo '9\\d*\\.\\d+\\.\\d+'",
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
		// alacritty installation dependency
		label: "Font config",
		commands: []string{
			"apt-get install libfontconfig1-dev -y",
		},
		healthCheckCommands: []string{
			"apt list --installed libfontconfig1-dev 2>/dev/null | grep -q '\\[installed\\]'",
		},
	},
	// alacritty installation is too slow, keep it at the end
	{
		label:  "Alacritty",
		asHome: true,
		commands: []string{
			"$HOME/.cargo/bin/cargo install alacritty",
		},
		healthCheckCommands: []string{
			"$HOME/.cargo/bin/alacritty --version",
		},
	},
}
