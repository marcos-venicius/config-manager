package commands

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
			"/opt/nvim/bin/vi --version",
		},
	},
	{
		label:    "Download & Build Helix",
		asHome:   true,
		disabled: true,
		commands: []string{
			"mkdir -p $HOME/.config/helix",
			"mkdir -p $HOME/tools",
			"git clone --depth 1 https://github.com/helix-editor/helix.git $HOME/tools/helix",
			"cd $HOME/tools/helix && $HOME/.cargo/bin/cargo build --release",
		},
		healthCheckCommands: []string{
			"$HOME/tools/helix/target/release/hx --version",
		},
	},
	{
		label:    "Install Helix",
		disabled: true,
		commands: []string{
			"ln -s $HOME/tools/helix/target/release/hx /usr/local/bin/hx",
			"ln -Tsf $HOME/tools/helix/runtime $HOME/.config/helix/runtime",
			"hx --grammar fetch",
			"hx --grammar build",
		},
		healthCheckCommands: []string{
			"hx --version",
			"find $HOME/.config/helix/runtime/grammars -type f -name '*.so' 2>/dev/null | grep -qoP '.*.so'",
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
		label: "GO Lang",
		commands: []string{
			"mkdir /tmp/golang-installation",
			"wget https://go.dev/dl/go1.26.1.linux-amd64.tar.gz -O /tmp/golang-installation/go1.26.1.linux-amd64.tar.gz",
			"rm -rf /opt/go && tar -C /opt -xzf /tmp/golang-installation/go1.26.1.linux-amd64.tar.gz",
			"rm -rf /tmp/golang-installation",
		},
		healthCheckCommands: []string{
			"/opt/go/bin/go version",
		},
	},
	{
		label: "Nim",
		commands: []string{
			"curl https://nim-lang.org/choosenim/init.sh -sSf | sh",
		},
		healthCheckCommands: []string{
			"$HOME/.nimble/bin/nim --version",
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
