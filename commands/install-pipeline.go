package commands

import "fmt"

var installationSteps = []step_t{
	{
		label:  "APT GET Update",
		groups: []string{"base"},
		commands: []string{
			"apt-get update -y",
			"apt-get upgrade -y",
		},
	},
	{
		label:  "Install add-apt-repository",
		groups: []string{"base"},
		commands: []string{
			"apt-get install software-properties-common -y",
		},
		healthCheckCommands: []string{
			"add-apt-repository --help",
		},
	},
	{
		label:  "Curl + Wget",
		groups: []string{"base"},
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
		label:  "Build Essentials",
		groups: []string{"base"},
		commands: []string{
			"apt-get install build-essential -y",
		},
		healthCheckCommands: []string{
			"gcc --version",
			"make --version",
		},
	},
	{
		label:  "Install CLang",
		groups: []string{"clang"},
		commands: []string{
			"apt-get install clang -y",
		},
		healthCheckCommands: []string{
			"clang --version",
		},
	},
	{
		label:  "Ripgrep",
		groups: []string{"ripgrep"},
		commands: []string{
			"apt-get install ripgrep -y",
		},
		healthCheckCommands: []string{
			"rg --version",
		},
	},
	{
		label:  "XClip",
		groups: []string{"clipboard"},
		commands: []string{
			"apt-get install xclip -y",
		},
		healthCheckCommands: []string{
			"xclip -version",
		},
	},
	{
		// clipboard on wayland sessions (tmux falls back to xclip on X11)
		label:  "WL Clipboard",
		groups: []string{"clipboard"},
		commands: []string{
			"apt-get install wl-clipboard -y",
		},
		healthCheckCommands: []string{
			"which wl-copy",
		},
	},
	{
		label:  "GIT",
		groups: []string{"git"},
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
		label:  "Kubectl",
		groups: []string{"kubectl"},
		commands: []string{
			"apt-get install ca-certificates gnupg -y",
			"mkdir -p -m 755 /etc/apt/keyrings",
			"curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
			"echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' > /etc/apt/sources.list.d/kubernetes.list",
			"apt-get update -y",
			"apt-get install kubectl -y",
		},
		healthCheckCommands: []string{
			"kubectl version --client",
		},
	},
	{
		label:  "Cargo",
		groups: []string{"cargo"},
		asHome: true,
		commands: []string{
			"curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rustc.sh",
			"chmod u+x /tmp/rustc.sh",
			// PATH is handled by configs/.bashrc
			"/tmp/rustc.sh -y --no-modify-path",
			"rm -rf /tmp/rustc.sh",
		},
		healthCheckCommands: []string{
			"$HOME/.cargo/bin/cargo --version",
		},
	},
	{
		label:  "Tmux",
		groups: []string{"tmux"},
		commands: []string{
			"apt-get install tmux -y",
		},
		healthCheckCommands: []string{
			"which tmux",
		},
	},
	{
		// helix is the only editor: purge any vim/neovim package and leftovers from the old neovim step
		label:  "Remove Vim",
		groups: []string{"helix"},
		commands: []string{
			"pkgs=$(dpkg -l | awk '/^ii/ && $2 ~ /^(vim|neovim)([-:]|$)/ {print $2}'); [ -z \"$pkgs\" ] || apt-get purge -y $pkgs",
			"apt-get autoremove -y",
			"rm -rf /opt/nvim",
		},
		healthCheckCommands: []string{
			"! dpkg -l | awk '/^ii/ && $2 ~ /^(vim|neovim)([-:]|$)/' | grep -q .",
			"[ ! -e /opt/nvim ]",
		},
	},
	{
		label:    "Download & Build Helix",
		groups:   []string{"helix"},
		requires: []string{"cargo", "git"},
		asHome:   true,
		commands: []string{
			"mkdir -p $HOME/.config/helix",
			"mkdir -p $HOME/tools",
			"[ -d $HOME/tools/helix ] || git clone --depth 1 https://github.com/helix-editor/helix.git $HOME/tools/helix",
			"cd $HOME/tools/helix && $HOME/.cargo/bin/cargo build --release",
		},
		healthCheckCommands: []string{
			"$HOME/tools/helix/target/release/hx --version",
		},
		updateCommands: []string{
			"cd $HOME/tools/helix && git pull --ff-only",
			"cd $HOME/tools/helix && $HOME/.cargo/bin/cargo build --release",
		},
	},
	{
		// runs as root, so $HOME is not the user's home
		label:  "Install Helix",
		groups: []string{"helix"},
		commands: []string{
			"ln -sf \"$(getent passwd \"$SUDO_USER\" | cut -d: -f6)/tools/helix/target/release/hx\" /usr/local/bin/hx",
		},
		healthCheckCommands: []string{
			"[ \"$(readlink /usr/local/bin/hx)\" = \"$HOME/tools/helix/target/release/hx\" ]",
			"hx --version",
		},
		uninstallCommands: []string{
			"rm -f /usr/local/bin/hx",
		},
	},
	{
		label:  "Helix runtime & grammars",
		groups: []string{"helix"},
		asHome: true,
		commands: []string{
			"ln -Tsf $HOME/tools/helix/runtime $HOME/.config/helix/runtime",
			"hx --grammar fetch",
			"hx --grammar build",
		},
		// a newer helix ships newer grammars
		updateCommands: []string{
			"hx --grammar fetch",
			"hx --grammar build",
		},
		healthCheckCommands: []string{
			"[ \"$(readlink $HOME/.config/helix/runtime)\" = \"$HOME/tools/helix/runtime\" ]",
			"find $HOME/.config/helix/runtime/grammars -type f -name '*.so' 2>/dev/null | grep -qoP '.*.so'",
		},
	},
	{
		label:  "Helix as default editor",
		groups: []string{"helix"},
		commands: []string{
			"update-alternatives --install /usr/bin/editor editor /usr/local/bin/hx 100",
			"update-alternatives --set editor /usr/local/bin/hx",
			"update-alternatives --install /usr/bin/vi vi /usr/local/bin/hx 100",
			"update-alternatives --set vi /usr/local/bin/hx",
		},
		healthCheckCommands: []string{
			"[ \"$(readlink -f /usr/bin/editor)\" = \"$(readlink -f /usr/local/bin/hx)\" ]",
			"[ \"$(readlink -f /usr/bin/vi)\" = \"$(readlink -f /usr/local/bin/hx)\" ]",
		},
		uninstallCommands: []string{
			"update-alternatives --remove editor /usr/local/bin/hx",
			"update-alternatives --remove vi /usr/local/bin/hx",
		},
	},
	{
		label:  "Dotnet",
		groups: []string{"dotnet"},
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
		label:  "GO Lang",
		groups: []string{"go"},
		commands: []string{
			"rm -rf /tmp/golang-installation && mkdir -p /tmp/golang-installation",
			"wget https://go.dev/dl/go1.26.1.linux-amd64.tar.gz -O /tmp/golang-installation/go1.26.1.linux-amd64.tar.gz",
			"rm -rf /opt/go && tar -C /opt -xzf /tmp/golang-installation/go1.26.1.linux-amd64.tar.gz",
			"rm -rf /tmp/golang-installation",
		},
		healthCheckCommands: []string{
			"/opt/go/bin/go version",
		},
	},
	{
		label:  "Nim",
		groups: []string{"nim"},
		asHome: true,
		commands: []string{
			"curl https://nim-lang.org/choosenim/init.sh -sSf > /tmp/choosenim-init.sh",
			"chmod u+x /tmp/choosenim-init.sh",
			"/tmp/choosenim-init.sh -y",
			// PATH is handled by configs/.bashrc
			"rm /tmp/choosenim-init.sh",
		},
		healthCheckCommands: []string{
			"$HOME/.nimble/bin/nim --version",
		},
	},
	{
		label:    "Download & Build Tmuxer",
		groups:   []string{"tmuxer"},
		requires: []string{"nim", "git"},
		asHome:   true,
		commands: []string{
			"mkdir -p $HOME/tools",
			"[ -d $HOME/tools/tmuxer ] || git clone --depth 1 https://github.com/marcos-venicius/tmuxer.git $HOME/tools/tmuxer",
			// nimble shells out to a bare `nim`, and this shell does not read .bashrc
			"cd $HOME/tools/tmuxer && PATH=$HOME/.nimble/bin:$PATH nimble build -d:release -y",
		},
		healthCheckCommands: []string{
			"$HOME/tools/tmuxer/bin/tmuxer -h",
		},
		updateCommands: []string{
			"cd $HOME/tools/tmuxer && git pull --ff-only",
			"cd $HOME/tools/tmuxer && PATH=$HOME/.nimble/bin:$PATH nimble build -d:release -y",
		},
	},
	{
		// runs as root, so $HOME is not the user's home
		label:  "Install Tmuxer",
		groups: []string{"tmuxer"},
		commands: []string{
			"ln -sf \"$(getent passwd \"$SUDO_USER\" | cut -d: -f6)/tools/tmuxer/bin/tmuxer\" /usr/local/bin/tmuxer",
		},
		healthCheckCommands: []string{
			"[ \"$(readlink /usr/local/bin/tmuxer)\" = \"$HOME/tools/tmuxer/bin/tmuxer\" ]",
			"tmuxer -h",
		},
		uninstallCommands: []string{
			"rm -f /usr/local/bin/tmuxer",
		},
	},
	{
		// mark renders into a native WebKitGTK window
		label:  "Mark dependencies",
		groups: []string{"mark"},
		commands: []string{
			"apt-get install pkg-config libwebkit2gtk-4.1-dev libsoup-3.0-dev -y",
		},
		healthCheckCommands: []string{
			// the .pc files are what the build actually looks for; on the first
			// run pkg-config itself is missing, which fails the check and runs the step
			"pkg-config --exists webkit2gtk-4.1",
			"pkg-config --exists libsoup-3.0",
		},
	},
	{
		label:    "Download & Install Mark",
		groups:   []string{"mark"},
		requires: []string{"cargo", "git"},
		asHome:   true,
		commands: []string{
			"mkdir -p $HOME/tools",
			"[ -d $HOME/tools/mark ] || git clone --depth 1 https://github.com/marcos-venicius/mark.git $HOME/tools/mark",
			// install.sh builds, installs to ~/.local/bin and registers the icon,
			// desktop entry and .md MIME type; it calls a bare `cargo`
			"cd $HOME/tools/mark && PATH=$HOME/.cargo/bin:$PATH ./install.sh",
		},
		healthCheckCommands: []string{
			"$HOME/.local/bin/mark --version",
			"[ -s $HOME/.local/share/applications/mark.desktop ]",
		},
		updateCommands: []string{
			"cd $HOME/tools/mark && git pull --ff-only",
			"cd $HOME/tools/mark && PATH=$HOME/.cargo/bin:$PATH ./install.sh",
		},
		// mark ships the exact inverse of its installer
		uninstallCommands: []string{
			"! [ -x $HOME/tools/mark/uninstall.sh ] || (cd $HOME/tools/mark && ./uninstall.sh)",
		},
	},
	{
		// alacritty installation dependency
		label:  "Font config",
		groups: []string{"alacritty"},
		commands: []string{
			"apt-get install libfontconfig1-dev -y",
		},
		healthCheckCommands: []string{
			"apt list --installed libfontconfig1-dev 2>/dev/null | grep -q '\\[installed\\]'",
		},
	},
	// keep it after every installer that may touch the dotfiles
	linkConfigsStep(),
	// alacritty installation is too slow, keep it (and its defaults) at the end
	{
		label:    "Alacritty",
		groups:   []string{"alacritty"},
		requires: []string{"cargo"},
		asHome:   true,
		commands: []string{
			"$HOME/.cargo/bin/cargo install alacritty",
		},
		healthCheckCommands: []string{
			"$HOME/.cargo/bin/alacritty --version",
		},
		uninstallCommands: []string{
			"$HOME/.cargo/bin/cargo uninstall alacritty",
		},
	},
	{
		// cargo install does not ship the desktop entry nor the icon
		label:    "Alacritty as default terminal",
		groups:   []string{"alacritty"},
		requires: []string{"cargo"},
		asHome:   true,
		commands: []string{
			"mkdir -p $HOME/.local/share/applications $HOME/.local/share/icons/hicolor/scalable/apps",
			`set -o pipefail; curl -fsSL https://raw.githubusercontent.com/alacritty/alacritty/master/extra/linux/Alacritty.desktop | sed -E "s#^(TryExec|Exec)=alacritty#\1=$HOME/.cargo/bin/alacritty#" > $HOME/.local/share/applications/Alacritty.desktop`,
			"curl -fsSL https://raw.githubusercontent.com/alacritty/alacritty/master/extra/logo/alacritty-term.svg -o $HOME/.local/share/icons/hicolor/scalable/apps/Alacritty.svg",
			"! command -v update-desktop-database >/dev/null || update-desktop-database $HOME/.local/share/applications",
			"! command -v xdg-mime >/dev/null || xdg-mime default Alacritty.desktop x-scheme-handler/terminal application/x-terminal-emulator",
			// COSMIC terminal shortcut
			`f=$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/system_actions; ` +
				`new=$(printf '{\n    Terminal: "%s",\n}' "$HOME/.cargo/bin/alacritty"); ` +
				`mkdir -p "$(dirname "$f")" && ` +
				`if [ -f "$f" ] && [ "$(cat "$f")" != "$new" ]; then cp "$f" "$f.bak.$(date +%s)"; fi && ` +
				`printf '%s\n' "$new" > "$f"`,
		},
		healthCheckCommands: []string{
			`grep -qx "Exec=$HOME/.cargo/bin/alacritty" $HOME/.local/share/applications/Alacritty.desktop`,
			"[ -s $HOME/.local/share/icons/hicolor/scalable/apps/Alacritty.svg ]",
			`! command -v xdg-mime >/dev/null || [ "$(xdg-mime query default x-scheme-handler/terminal)" = Alacritty.desktop ]`,
			`grep -qF "Terminal: \"$HOME/.cargo/bin/alacritty\"" $HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/system_actions`,
		},
		// the COSMIC shortcut file is left alone: the install backed the previous one
		// up next to it, and guessing which backup to restore is worse than doing nothing
		uninstallCommands: []string{
			"rm -f $HOME/.local/share/applications/Alacritty.desktop",
			"rm -f $HOME/.local/share/icons/hicolor/scalable/apps/Alacritty.svg",
			"! command -v update-desktop-database >/dev/null || update-desktop-database $HOME/.local/share/applications",
		},
	},
	{
		// runs as root, so $HOME is not the user's home
		label:    "Alacritty as x-terminal-emulator",
		groups:   []string{"alacritty"},
		requires: []string{"cargo"},
		commands: []string{
			`update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$(getent passwd "$SUDO_USER" | cut -d: -f6)/.cargo/bin/alacritty" 60`,
			`update-alternatives --set x-terminal-emulator "$(getent passwd "$SUDO_USER" | cut -d: -f6)/.cargo/bin/alacritty"`,
		},
		healthCheckCommands: []string{
			`[ "$(readlink -f /usr/bin/x-terminal-emulator)" = "$HOME/.cargo/bin/alacritty" ]`,
		},
		uninstallCommands: []string{
			`update-alternatives --remove x-terminal-emulator "$(getent passwd "$SUDO_USER" | cut -d: -f6)/.cargo/bin/alacritty"`,
		},
	},
}

// repository root; defaults to the clone location described in the README
const configManagerDir = "${CONFIG_MANAGER_DIR:-$HOME/.config-manager}"

// linkConfig symlinks configs/<src> to dst, moving any existing non-symlink dst to dst.bak.<timestamp>.
// unlink only removes dst when it still points at this repository, so a link the user
// repointed somewhere else survives; the .bak copies are left where the install put them.
func linkConfig(src, dst string) (command string, healthCheck string, unlink string) {
	target := configManagerDir + "/configs/" + src

	command = fmt.Sprintf(
		`test -e "%[1]s" && mkdir -p "$(dirname "%[2]s")" && if [ -e "%[2]s" ] && [ ! -L "%[2]s" ]; then mv "%[2]s" "%[2]s.bak.$(date +%%s)"; fi && ln -sfn "%[1]s" "%[2]s"`,
		target, dst,
	)
	healthCheck = fmt.Sprintf(`[ "$(readlink "%s")" = "%s" ]`, dst, target)
	unlink = fmt.Sprintf(`! [ "$(readlink "%[2]s")" = "%[1]s" ] || rm -f "%[2]s"`, target, dst)

	return command, healthCheck, unlink
}

func linkConfigsStep() step_t {
	links := [][2]string{
		{".bashrc", "$HOME/.bashrc"},
		{".gitconfig", "$HOME/.gitconfig"},
		{".tmux.conf", "$HOME/.tmux.conf"},
		{"alacritty", "$HOME/.config/alacritty"},
		{"helix/config.toml", "$HOME/.config/helix/config.toml"},
		{"helix/languages.toml", "$HOME/.config/helix/languages.toml"},
	}

	step := step_t{
		label:  "Link configs",
		groups: []string{"configs"},
		asHome: true,
		commands: []string{
			`echo 'SELECTED_EDITOR="/usr/local/bin/hx"' > $HOME/.selected_editor`,
		},
		healthCheckCommands: []string{
			`grep -qx 'SELECTED_EDITOR="/usr/local/bin/hx"' $HOME/.selected_editor`,
		},
		uninstallCommands: []string{
			`rm -f $HOME/.selected_editor`,
		},
	}

	for _, link := range links {
		command, healthCheck, unlink := linkConfig(link[0], link[1])

		step.commands = append(step.commands, command)
		step.healthCheckCommands = append(step.healthCheckCommands, healthCheck)
		step.uninstallCommands = append(step.uninstallCommands, unlink)
	}

	return step
}
