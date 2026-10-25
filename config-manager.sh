#!/usr/bin/env bash
#
# config-manager: one script that turns a fresh Ubuntu install into a ready-to-code
# machine. Run `./config-manager.sh help` for usage.
set -u
set -o pipefail

VERSION="4.0.0"
IMPLICIT_GROUP="base"

CLR_BLUE=$'\033[0;34m'
CLR_DIM=$'\033[2;36m'
CLR_YELLOW=$'\033[0;33m'
CLR_GREEN=$'\033[0;32m'
CLR_BGREEN=$'\033[1;32m'
CLR_RED=$'\033[0;31m'
CLR_BRED=$'\033[1;31m'
CLR_CYAN=$'\033[0;36m'
CLR_GRAY=$'\033[2;38m'
CLR_RESET=$'\033[0m'

# ---------------------------------------------------------------------------
# step registry
# ---------------------------------------------------------------------------
# a step is registered by defining CMDS_<id>, HEALTH_<id>, UPDATE_<id> and
# UNINSTALL_<id> arrays (empty when not applicable) and then calling
# `step <id> <label> <groups> <requires> <as_home:0|1>`.

declare -a STEP_IDS=()
declare -A STEP_LABEL=()
declare -A STEP_GROUPS=()
declare -A STEP_REQUIRES=()
declare -A STEP_ASHOME=()
declare -A STEP_DISABLED=()

step() {
	local id="$1" label="$2" groups="$3" requires="$4" as_home="$5"

	STEP_IDS+=("$id")
	STEP_LABEL["$id"]="$label"
	STEP_GROUPS["$id"]="$groups"
	STEP_REQUIRES["$id"]="$requires"
	STEP_ASHOME["$id"]="$as_home"
	STEP_DISABLED["$id"]="0"
}

join_comma() {
	local out="" first=1 a
	for a in "$@"; do
		if [ "$first" = "1" ]; then
			out="$a"
			first=0
		else
			out="$out, $a"
		fi
	done
	printf '%s' "$out"
}

group_in_list() {
	local needle="$1" hay="$2" g
	for g in $hay; do
		[ "$g" = "$needle" ] && return 0
	done
	return 1
}

# ===========================================================================
# installation steps
# ===========================================================================

CMDS_apt_update=(
	'apt-get update -y'
	'apt-get upgrade -y'
)
HEALTH_apt_update=()
UPDATE_apt_update=()
UNINSTALL_apt_update=()
step apt_update "APT GET Update" "base" "" "0"

CMDS_utillinux=(
	'apt-get install util-linux-extra -y'
)
HEALTH_utillinux=(
	'which newgrp'
)
UPDATE_utillinux=()
UNINSTALL_utillinux=(
	'apt-get remove util-linux-extra -y'
)
step utillinux "Util Linux Extra" "base" "" "0"

CMDS_curlwget=(
	'apt-get install curl -y'
	'apt-get install wget -y'
	'apt-get install ca-certificates -y'
)
HEALTH_curlwget=(
	'wget --version'
	'curl --version'
	'dpkg -s ca-certificates'
)
UPDATE_curlwget=()
UNINSTALL_curlwget=()
step curlwget "Curl + Wget + Ca-Certificates" "base" "" "0"

CMDS_addaptrepo=(
	'apt-get install software-properties-common -y'
)
HEALTH_addaptrepo=(
	'add-apt-repository --help'
)
UPDATE_addaptrepo=()
UNINSTALL_addaptrepo=()
step addaptrepo "Install add-apt-repository" "base" "" "0"

CMDS_buildessential=(
	'apt-get install build-essential -y'
)
HEALTH_buildessential=(
	'gcc --version'
	'make --version'
)
UPDATE_buildessential=()
UNINSTALL_buildessential=()
step buildessential "Build Essentials" "base" "" "0"

read -r -d '' CMD_DOCKER_SOURCE_TEE <<'CMDEOF' || true
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
CMDEOF

CMDS_docker=(
	'apt-get remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc | cut -f1) -y'
	'install -m 0755 -d /etc/apt/keyrings'
	'curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc'
	'chmod a+r /etc/apt/keyrings/docker.asc'
	"$CMD_DOCKER_SOURCE_TEE"
	'apt-get update -y'
	'apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y'
	'systemctl enable docker'
	'systemctl start docker'
	'groupadd docker || :'
	'usermod -aG docker $(logname) || :'
)
HEALTH_docker=(
	'which docker'
)
UPDATE_docker=()
UNINSTALL_docker=(
	'systemctl disable docker'
	'apt purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras'
	'rm -rf /var/lib/docker'
	'rm -rf /var/lib/containerd'
	'rm /etc/apt/sources.list.d/docker.sources'
	'rm /etc/apt/keyrings/docker.asc'
)
step docker "Install Docker" "docker" "base" "0"

CMDS_font=(
	'wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip'
	'cd ~/.local/share/fonts && unzip JetBrainsMono.zip && rm JetBrainsMono.zip'
	'fc-cache -f -v'
)
HEALTH_font=(
	'ls -lah ~/.local/share/fonts/ | grep "JetBrainsMono*"'
)
UPDATE_font=()
UNINSTALL_font=(
	'rm -rf ~/.local/share/fonts/JetBrainsMono*'
)
step font "Font" "font" "" "1"

CMDS_clang=(
	'apt-get install clang -y'
)
HEALTH_clang=(
	'clang --version'
)
UPDATE_clang=()
UNINSTALL_clang=()
step clang "Install CLang" "clang" "" "0"

CMDS_ripgrep=(
	'apt-get install ripgrep -y'
)
HEALTH_ripgrep=(
	'rg --version'
)
UPDATE_ripgrep=()
UNINSTALL_ripgrep=()
step ripgrep "Ripgrep" "ripgrep" "" "0"

CMDS_xclip=(
	'apt-get install xclip -y'
)
HEALTH_xclip=(
	'xclip -version'
)
UPDATE_xclip=()
UNINSTALL_xclip=()
step xclip "XClip" "clipboard" "" "0"

CMDS_wlclipboard=(
	'apt-get install wl-clipboard -y'
)
HEALTH_wlclipboard=(
	'which wl-copy'
)
UPDATE_wlclipboard=()
UNINSTALL_wlclipboard=()
step wlclipboard "WL Clipboard" "clipboard" "" "0"

CMDS_git=(
	'add-apt-repository ppa:git-core/ppa -y'
	'apt-get update -y'
	'apt-get install git -y'
)
HEALTH_git=(
	'git --version'
)
UPDATE_git=()
UNINSTALL_git=()
step git "GIT" "git" "" "0"

CMDS_configmanager=(
	'git clone https://github.com/marcos-venicius/config-manager.git ~/.config-manager --depth=1'
)
HEALTH_configmanager=(
	'ls ~/.config-manager 2>/dev/null 1>/dev/null'
)
UPDATE_configmanager=()
UNINSTALL_configmanager=(
	'rm -rf ~/.config-manager'
)
step configmanager "Config Manager" "config-manager" "" "1"

CMDS_kubectl=(
	'apt-get install ca-certificates gnupg -y'
	'mkdir -p -m 755 /etc/apt/keyrings'
	'curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg'
	'echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /" > /etc/apt/sources.list.d/kubernetes.list'
	'apt-get update -y'
	'apt-get install kubectl -y'
)
HEALTH_kubectl=(
	'kubectl version --client'
)
UPDATE_kubectl=()
UNINSTALL_kubectl=()
step kubectl "Kubectl" "kubectl" "" "0"

CMDS_cargo=(
	'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rustc.sh'
	'chmod u+x /tmp/rustc.sh'
	'/tmp/rustc.sh -y --no-modify-path'
	'rm -rf /tmp/rustc.sh'
)
HEALTH_cargo=(
	'$HOME/.cargo/bin/cargo --version'
)
UPDATE_cargo=()
UNINSTALL_cargo=()
step cargo "Cargo" "cargo" "" "1"

CMDS_tmux=(
	'apt-get install tmux -y'
)
HEALTH_tmux=(
	'which tmux'
)
UPDATE_tmux=()
UNINSTALL_tmux=()
step tmux "Tmux" "tmux" "" "0"

CMDS_fzf=(
	'apt-get install fzf -y'
)
HEALTH_fzf=(
	'which fzf'
)
UPDATE_fzf=()
UNINSTALL_fzf=()
step fzf "Fzf" "fzf" "" "0"

CMDS_jq=(
	'apt-get install jq -y'
)
HEALTH_jq=(
	'which jq'
)
UPDATE_jq=()
UNINSTALL_jq=()
step jq "Jq" "jq" "" "0"

read -r -d '' CMD_REMOVE_VIM <<'CMDEOF' || true
pkgs=$(dpkg -l | awk '/^ii/ && $2 ~ /^(vim|neovim)([-:]|$)/ {print $2}'); [ -z "$pkgs" ] || apt-get purge -y $pkgs
CMDEOF
read -r -d '' HEALTH_REMOVE_VIM_PKGS <<'CMDEOF' || true
! dpkg -l | awk '/^ii/ && $2 ~ /^(vim|neovim)([-:]|$)/' | grep -q .
CMDEOF

CMDS_removevim=(
	"$CMD_REMOVE_VIM"
	'apt-get autoremove -y'
	'rm -rf /opt/nvim'
)
HEALTH_removevim=(
	"$HEALTH_REMOVE_VIM_PKGS"
	'[ ! -e /opt/nvim ]'
)
UPDATE_removevim=()
UNINSTALL_removevim=()
step removevim "Remove Vim" "helix" "" "0"

CMDS_buildhelix=(
	'mkdir -p $HOME/.config/helix'
	'mkdir -p $HOME/tools'
	'[ -d $HOME/tools/helix ] || git clone --branch marcos https://github.com/marcos-venicius/helix.git $HOME/tools/helix'
	'cd $HOME/tools/helix && git remote get-url origin | grep -q marcos-venicius/helix || { git remote set-url origin https://github.com/marcos-venicius/helix.git && git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*" && git fetch $([ -f .git/shallow ] && echo --unshallow) origin && git checkout -B marcos origin/marcos; }'
	'cd $HOME/tools/helix && { git remote get-url upstream >/dev/null 2>&1 || git remote add upstream https://github.com/helix-editor/helix.git; }'
	'cd $HOME/tools/helix && $HOME/.cargo/bin/cargo build --release'
)
HEALTH_buildhelix=(
	'git -C $HOME/tools/helix remote get-url origin | grep -q marcos-venicius/helix'
	'$HOME/tools/helix/target/release/hx --version'
)
read -r -d '' UPDATE_HELIX_PULL <<'CMDEOF' || true
cd $HOME/tools/helix && { [ "$(git branch --show-current)" = marcos ] || { echo "helix: ~/tools/helix is not on the marcos branch, skipping" >&2; exit 1; }; } && git pull --ff-only origin marcos
CMDEOF
read -r -d '' UPDATE_HELIX_BUILD <<'CMDEOF' || true
cd $HOME/tools/helix && { [ "$(git branch --show-current)" = marcos ] || { echo "helix: ~/tools/helix is not on the marcos branch, skipping" >&2; exit 1; }; } && $HOME/.cargo/bin/cargo build --release
CMDEOF
UPDATE_buildhelix=(
	"$UPDATE_HELIX_PULL"
	"$UPDATE_HELIX_BUILD"
)
UNINSTALL_buildhelix=()
step buildhelix "Download & Build Helix" "helix" "cargo git" "1"

CMDS_installhelix=(
	'ln -sf "$(getent passwd "$SUDO_USER" | cut -d: -f6)/tools/helix/target/release/hx" /usr/local/bin/hx'
	'ln -sf "$(getent passwd "$SUDO_USER" | cut -d: -f6)/tools/helix/target/release/hx" /usr/local/bin/h'
)
HEALTH_installhelix=(
	'[ "$(readlink /usr/local/bin/hx)" = "$HOME/tools/helix/target/release/hx" ]'
	'hx --version'
	'[ "$(readlink /usr/local/bin/h)" = "$HOME/tools/helix/target/release/hx" ]'
	'h --version'
)
UPDATE_installhelix=()
UNINSTALL_installhelix=(
	'rm -f /usr/local/bin/hx'
	'rm -f /usr/local/bin/h'
)
step installhelix "Install Helix" "helix" "" "0"

CMDS_helixruntime=(
	'ln -Tsf $HOME/tools/helix/runtime $HOME/.config/helix/runtime'
	'hx --grammar fetch'
	'hx --grammar build'
)
HEALTH_helixruntime=(
	'[ "$(readlink $HOME/.config/helix/runtime)" = "$HOME/tools/helix/runtime" ]'
	'find $HOME/.config/helix/runtime/grammars -type f -name "*.so" 2>/dev/null | grep -qoP ".*.so"'
)
UPDATE_helixruntime=(
	'hx --grammar fetch'
	'hx --grammar build'
)
UNINSTALL_helixruntime=()
step helixruntime "Helix runtime & grammars" "helix" "" "1"

CMDS_helixdefaulteditor=(
	'update-alternatives --install /usr/bin/editor editor /usr/local/bin/hx 100'
	'update-alternatives --set editor /usr/local/bin/hx'
	'update-alternatives --install /usr/bin/vi vi /usr/local/bin/hx 100'
	'update-alternatives --set vi /usr/local/bin/hx'
)
HEALTH_helixdefaulteditor=(
	'[ "$(readlink -f /usr/bin/editor)" = "$(readlink -f /usr/local/bin/hx)" ]'
	'[ "$(readlink -f /usr/bin/vi)" = "$(readlink -f /usr/local/bin/hx)" ]'
)
UPDATE_helixdefaulteditor=()
UNINSTALL_helixdefaulteditor=(
	'update-alternatives --remove editor /usr/local/bin/hx'
	'update-alternatives --remove vi /usr/local/bin/hx'
)
step helixdefaulteditor "Helix as default editor" "helix" "" "0"

CMDS_go=(
	'rm -rf /opt/go'
	'GO_LATEST=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -n1) && curl -fsSL "https://go.dev/dl/${GO_LATEST}.linux-amd64.tar.gz" -o /tmp/go.tar.gz'
	'tar -C /opt -xzf /tmp/go.tar.gz'
	'rm -f /tmp/go.tar.gz'
)
HEALTH_go=(
	'/opt/go/bin/go version'
)
UPDATE_go=()
UNINSTALL_go=()
step go "Go" "go" "" "0"

read -r -d '' CMD_ASDF_DOWNLOAD <<'CMDEOF' || true
ASDF_URL=$(curl -fsSL https://api.github.com/repos/asdf-vm/asdf/releases/latest | grep -oP '"browser_download_url":\s*"\K[^"]*linux-amd64\.tar\.gz(?=")' | head -n1) && curl -fsSL "$ASDF_URL" -o /tmp/asdf.tar.gz
CMDEOF

CMDS_asdf=(
	'mkdir -p $HOME/.asdf/bin'
	"$CMD_ASDF_DOWNLOAD"
	'tar -xzf /tmp/asdf.tar.gz -C $HOME/.asdf/bin'
	'rm -f /tmp/asdf.tar.gz'
)
HEALTH_asdf=(
	'$HOME/.asdf/bin/asdf version'
)
UPDATE_asdf=()
UNINSTALL_asdf=()
step asdf "Asdf" "asdf" "" "1"

read -r -d '' CMD_NODE_PLUGIN <<'CMDEOF' || true
PATH="$HOME/.asdf/bin:$PATH" asdf plugin list | grep -qx nodejs || PATH="$HOME/.asdf/bin:$PATH" asdf plugin add nodejs
CMDEOF
read -r -d '' CMD_NODE_INSTALL <<'CMDEOF' || true
NODE_LATEST=$(PATH="$HOME/.asdf/bin:$PATH" asdf latest nodejs) && PATH="$HOME/.asdf/bin:$PATH" asdf install nodejs "$NODE_LATEST" && PATH="$HOME/.asdf/bin:$PATH" asdf reshim nodejs "$NODE_LATEST"
CMDEOF
read -r -d '' CMD_NODE_GLOBAL <<'CMDEOF' || true
NODE_LATEST=$(PATH="$HOME/.asdf/bin:$PATH" asdf latest nodejs) && PATH="$HOME/.asdf/bin:$PATH" asdf set -u nodejs "$NODE_LATEST"
CMDEOF
read -r -d '' HEALTH_NODE_VERSION <<'CMDEOF' || true
PATH="$HOME/.asdf/bin:$PATH" asdf exec node --version
CMDEOF
read -r -d '' UPDATE_NODE_INSTALL <<'CMDEOF' || true
NODE_LATEST=$(PATH="$HOME/.asdf/bin:$PATH" asdf latest nodejs) && PATH="$HOME/.asdf/bin:$PATH" asdf install nodejs "$NODE_LATEST" && PATH="$HOME/.asdf/bin:$PATH" asdf reshim nodejs "$NODE_LATEST" && PATH="$HOME/.asdf/bin:$PATH" asdf set -u nodejs "$NODE_LATEST"
CMDEOF

CMDS_node=(
	"$CMD_NODE_PLUGIN"
	"$CMD_NODE_INSTALL"
	"$CMD_NODE_GLOBAL"
)
HEALTH_node=(
	"$HEALTH_NODE_VERSION"
)
UPDATE_node=(
	"$UPDATE_NODE_INSTALL"
)
UNINSTALL_node=()
step node "Node (via asdf)" "node" "asdf git" "1"

CMDS_dotnet=(
	'mkdir -p $HOME/tools/dotnet'
	'wget https://dot.net/v1/dotnet-install.sh -O $HOME/tools/dotnet/dotnet-install.sh'
	'chmod u+x $HOME/tools/dotnet/dotnet-install.sh'
	'$HOME/tools/dotnet/dotnet-install.sh --channel 9.0'
)
HEALTH_dotnet=(
	'$HOME/.dotnet/dotnet --list-sdks | grep -qPo "9\d*\.\d+\.\d+"'
)
UPDATE_dotnet=()
UNINSTALL_dotnet=()
step dotnet "Dotnet" "dotnet" "" "1"

CMDS_nim=(
	'curl https://nim-lang.org/choosenim/init.sh -sSf > /tmp/choosenim-init.sh'
	'chmod u+x /tmp/choosenim-init.sh'
	'/tmp/choosenim-init.sh -y'
	'rm /tmp/choosenim-init.sh'
)
HEALTH_nim=(
	'$HOME/.nimble/bin/nim --version'
)
UPDATE_nim=()
UNINSTALL_nim=()
step nim "Nim" "nim" "" "1"

CMDS_buildtmuxer=(
	'mkdir -p $HOME/tools'
	'[ -d $HOME/tools/tmuxer ] || git clone --depth 1 https://github.com/marcos-venicius/tmuxer.git $HOME/tools/tmuxer'
	'cd $HOME/tools/tmuxer && PATH=$HOME/.nimble/bin:$PATH nimble build -d:release -y'
)
HEALTH_buildtmuxer=(
	'$HOME/tools/tmuxer/bin/tmuxer -h'
)
UPDATE_buildtmuxer=(
	'cd $HOME/tools/tmuxer && git pull --ff-only'
	'cd $HOME/tools/tmuxer && PATH=$HOME/.nimble/bin:$PATH nimble build -d:release -y'
)
UNINSTALL_buildtmuxer=()
step buildtmuxer "Download & Build Tmuxer" "tmuxer" "nim git" "1"

CMDS_installtmuxer=(
	'ln -sf "$(getent passwd "$SUDO_USER" | cut -d: -f6)/tools/tmuxer/bin/tmuxer" /usr/local/bin/tmuxer'
)
HEALTH_installtmuxer=(
	'[ "$(readlink /usr/local/bin/tmuxer)" = "$HOME/tools/tmuxer/bin/tmuxer" ]'
	'tmuxer -h'
)
UPDATE_installtmuxer=()
UNINSTALL_installtmuxer=(
	'rm -f /usr/local/bin/tmuxer'
)
step installtmuxer "Install Tmuxer" "tmuxer" "" "0"

CMDS_markdeps=(
	'apt-get install pkg-config libwebkit2gtk-4.1-dev libsoup-3.0-dev -y'
)
HEALTH_markdeps=(
	'pkg-config --exists webkit2gtk-4.1'
	'pkg-config --exists libsoup-3.0'
)
UPDATE_markdeps=()
UNINSTALL_markdeps=()
step markdeps "Mark dependencies" "mark" "" "0"

CMDS_mark=(
	'mkdir -p $HOME/tools'
	'[ -d $HOME/tools/mark ] || git clone --depth 1 https://github.com/marcos-venicius/mark.git $HOME/tools/mark'
	'cd $HOME/tools/mark && PATH=$HOME/.cargo/bin:$PATH ./install.sh'
)
HEALTH_mark=(
	'$HOME/.local/bin/mark --version'
	'[ -s $HOME/.local/share/applications/mark.desktop ]'
)
UPDATE_mark=(
	'cd $HOME/tools/mark && git pull --ff-only'
	'cd $HOME/tools/mark && PATH=$HOME/.cargo/bin:$PATH ./install.sh'
)
UNINSTALL_mark=(
	'! [ -x $HOME/tools/mark/uninstall.sh ] || (cd $HOME/tools/mark && ./uninstall.sh)'
)
step mark "Download & Install Mark" "mark" "cargo git" "1"

CMDS_claude=(
	'curl -fsSL https://claude.ai/install.sh > /tmp/claude-install.sh'
	'chmod u+x /tmp/claude-install.sh'
	'PATH=$HOME/.local/bin:$PATH /tmp/claude-install.sh'
	'rm -f /tmp/claude-install.sh'
)
HEALTH_claude=(
	'$HOME/.local/bin/claude --version'
)
UPDATE_claude=(
	'PATH=$HOME/.local/bin:$PATH claude update'
)
UNINSTALL_claude=(
	'rm -f $HOME/.local/bin/claude'
	'rm -rf $HOME/.local/share/claude'
)
step claude "Claude Code" "claude" "" "1"

CMDS_fontconfig=(
	'apt-get install libfontconfig1-dev -y'
)
HEALTH_fontconfig=(
	'apt list --installed libfontconfig1-dev 2>/dev/null | grep -q "\[installed\]"'
)
UPDATE_fontconfig=()
UNINSTALL_fontconfig=()
step fontconfig "Font config" "alacritty" "" "0"

# ---------------------------------------------------------------------------
# Link configs: symlinks every file in configs/ into $HOME
# ---------------------------------------------------------------------------

CMDS_linkconfigs=(
	'echo "SELECTED_EDITOR=\"/usr/local/bin/hx\"" > $HOME/.selected_editor'
	'target="${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/.bashrc"; dst="$HOME/.bashrc"; test -e "$target" && mkdir -p "$(dirname "$dst")" && if [ -e "$dst" ] && [ ! -L "$dst" ]; then mv "$dst" "$dst.bak.$(date +%s)"; fi && ln -sfn "$target" "$dst"'
	'target="${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/.gitconfig"; dst="$HOME/.gitconfig"; test -e "$target" && mkdir -p "$(dirname "$dst")" && if [ -e "$dst" ] && [ ! -L "$dst" ]; then mv "$dst" "$dst.bak.$(date +%s)"; fi && ln -sfn "$target" "$dst"'
	'target="${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/.tmux.conf"; dst="$HOME/.tmux.conf"; test -e "$target" && mkdir -p "$(dirname "$dst")" && if [ -e "$dst" ] && [ ! -L "$dst" ]; then mv "$dst" "$dst.bak.$(date +%s)"; fi && ln -sfn "$target" "$dst"'
	'target="${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/alacritty"; dst="$HOME/.config/alacritty"; test -e "$target" && mkdir -p "$(dirname "$dst")" && if [ -e "$dst" ] && [ ! -L "$dst" ]; then mv "$dst" "$dst.bak.$(date +%s)"; fi && ln -sfn "$target" "$dst"'
	'target="${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/helix/config.toml"; dst="$HOME/.config/helix/config.toml"; test -e "$target" && mkdir -p "$(dirname "$dst")" && if [ -e "$dst" ] && [ ! -L "$dst" ]; then mv "$dst" "$dst.bak.$(date +%s)"; fi && ln -sfn "$target" "$dst"'
	'target="${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/helix/languages.toml"; dst="$HOME/.config/helix/languages.toml"; test -e "$target" && mkdir -p "$(dirname "$dst")" && if [ -e "$dst" ] && [ ! -L "$dst" ]; then mv "$dst" "$dst.bak.$(date +%s)"; fi && ln -sfn "$target" "$dst"'
)
HEALTH_linkconfigs=(
	'grep -qx "SELECTED_EDITOR=\"/usr/local/bin/hx\"" $HOME/.selected_editor'
	'[ "$(readlink "$HOME/.bashrc")" = "${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/.bashrc" ]'
	'[ "$(readlink "$HOME/.gitconfig")" = "${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/.gitconfig" ]'
	'[ "$(readlink "$HOME/.tmux.conf")" = "${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/.tmux.conf" ]'
	'[ "$(readlink "$HOME/.config/alacritty")" = "${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/alacritty" ]'
	'[ "$(readlink "$HOME/.config/helix/config.toml")" = "${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/helix/config.toml" ]'
	'[ "$(readlink "$HOME/.config/helix/languages.toml")" = "${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/helix/languages.toml" ]'
)
UPDATE_linkconfigs=()
UNINSTALL_linkconfigs=(
	'rm -f $HOME/.selected_editor'
	'target="${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/.bashrc"; dst="$HOME/.bashrc"; ! [ "$(readlink "$dst")" = "$target" ] || rm -f "$dst"'
	'target="${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/.gitconfig"; dst="$HOME/.gitconfig"; ! [ "$(readlink "$dst")" = "$target" ] || rm -f "$dst"'
	'target="${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/.tmux.conf"; dst="$HOME/.tmux.conf"; ! [ "$(readlink "$dst")" = "$target" ] || rm -f "$dst"'
	'target="${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/alacritty"; dst="$HOME/.config/alacritty"; ! [ "$(readlink "$dst")" = "$target" ] || rm -f "$dst"'
	'target="${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/helix/config.toml"; dst="$HOME/.config/helix/config.toml"; ! [ "$(readlink "$dst")" = "$target" ] || rm -f "$dst"'
	'target="${CONFIG_MANAGER_DIR:-$HOME/.config-manager}/configs/helix/languages.toml"; dst="$HOME/.config/helix/languages.toml"; ! [ "$(readlink "$dst")" = "$target" ] || rm -f "$dst"'
)
step linkconfigs "Link configs" "configs" "config-manager" "1"

CMDS_tpm=(
	'mkdir -p $HOME/.tmux/plugins'
	'[ -d $HOME/.tmux/plugins/tpm ] || git clone --depth 1 https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm'
	'$HOME/.tmux/plugins/tpm/bin/install_plugins'
)
HEALTH_tpm=(
	'[ -x $HOME/.tmux/plugins/tpm/tpm ]'
	'[ -d $HOME/.tmux/plugins/tmux ]'
	'[ -d $HOME/.tmux/plugins/tmux-claude-hatch ]'
)
UPDATE_tpm=(
	'cd $HOME/.tmux/plugins/tpm && git pull --ff-only'
	'$HOME/.tmux/plugins/tpm/bin/update_plugins all'
)
UNINSTALL_tpm=(
	'rm -rf $HOME/.tmux/plugins'
)
step tpm "Tmux Plugin Manager" "tpm" "tmux configs git fzf jq" "1"

read -r -d '' HEALTH_CLAUDE_HATCH <<'CMDEOF' || true
PATH=$HOME/.local/bin:$PATH claude plugin list --json | jq -e 'any(.[]; .id == "tmux-claude-hatch@tmux-claude-hatch")'
CMDEOF

CMDS_claudehatch=(
	'PATH=$HOME/.local/bin:$PATH; claude plugin marketplace list | grep -q tmux-claude-hatch || claude plugin marketplace add craftzdog/tmux-claude-hatch'
	'PATH=$HOME/.local/bin:$PATH claude plugin install tmux-claude-hatch@tmux-claude-hatch'
)
HEALTH_claudehatch=(
	"$HEALTH_CLAUDE_HATCH"
)
UPDATE_claudehatch=(
	'PATH=$HOME/.local/bin:$PATH claude plugin marketplace update tmux-claude-hatch'
	'PATH=$HOME/.local/bin:$PATH claude plugin update tmux-claude-hatch@tmux-claude-hatch'
)
UNINSTALL_claudehatch=(
	'PATH=$HOME/.local/bin:$PATH claude plugin uninstall tmux-claude-hatch@tmux-claude-hatch'
	'PATH=$HOME/.local/bin:$PATH claude plugin marketplace remove tmux-claude-hatch'
)
step claudehatch "Claude Hatch plugin" "claude-hatch" "claude jq" "1"

read -r -d '' CMD_CLAUDE_BELL_SETTINGS <<'CMDEOF' || true
f=$HOME/.claude/settings.json; [ -s $f ] || echo '{}' > $f; json=$(jq '.preferredNotifChannel = "terminal_bell"' $f) && echo "$json" > $f
CMDEOF
read -r -d '' CMD_CLAUDE_BELL_JSON <<'CMDEOF' || true
f=$HOME/.claude.json; [ -s $f ] || echo '{}' > $f; json=$(jq '.messageIdleNotifThresholdMs = 0' $f) && echo "$json" > $f
CMDEOF
read -r -d '' HEALTH_CLAUDE_BELL_SETTINGS <<'CMDEOF' || true
jq -e '.preferredNotifChannel == "terminal_bell"' $HOME/.claude/settings.json
CMDEOF
read -r -d '' HEALTH_CLAUDE_BELL_JSON <<'CMDEOF' || true
jq -e '.messageIdleNotifThresholdMs == 0' $HOME/.claude.json
CMDEOF
read -r -d '' UNINSTALL_CLAUDE_BELL_SETTINGS <<'CMDEOF' || true
f=$HOME/.claude/settings.json; json=$(jq 'del(.preferredNotifChannel)' $f) && echo "$json" > $f
CMDEOF
read -r -d '' UNINSTALL_CLAUDE_BELL_JSON <<'CMDEOF' || true
f=$HOME/.claude.json; json=$(jq 'del(.messageIdleNotifThresholdMs)' $f) && echo "$json" > $f
CMDEOF

CMDS_claudebell=(
	'mkdir -p $HOME/.claude && touch $HOME/.claude.json && chmod 600 $HOME/.claude.json'
	"$CMD_CLAUDE_BELL_SETTINGS"
	"$CMD_CLAUDE_BELL_JSON"
)
HEALTH_claudebell=(
	"$HEALTH_CLAUDE_BELL_SETTINGS"
	"$HEALTH_CLAUDE_BELL_JSON"
)
UPDATE_claudebell=()
UNINSTALL_claudebell=(
	"$UNINSTALL_CLAUDE_BELL_SETTINGS"
	"$UNINSTALL_CLAUDE_BELL_JSON"
)
step claudebell "Claude bell notifications" "claude-hatch" "claude jq" "1"

CMDS_alacritty=(
	'$HOME/.cargo/bin/cargo install alacritty'
)
HEALTH_alacritty=(
	'$HOME/.cargo/bin/alacritty --version'
)
UPDATE_alacritty=()
UNINSTALL_alacritty=(
	'$HOME/.cargo/bin/cargo uninstall alacritty'
)
step alacritty "Alacritty" "alacritty" "cargo" "1"

read -r -d '' CMD_ALACRITTY_DESKTOP <<'CMDEOF' || true
set -o pipefail; curl -fsSL https://raw.githubusercontent.com/alacritty/alacritty/master/extra/linux/Alacritty.desktop | sed -E "s#^(TryExec|Exec)=alacritty#\1=$HOME/.cargo/bin/alacritty#" > $HOME/.local/share/applications/Alacritty.desktop
CMDEOF
read -r -d '' CMD_ALACRITTY_COSMIC <<'CMDEOF' || true
f=$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/system_actions; new=$(printf '{\n    Terminal: "%s",\n}' "$HOME/.cargo/bin/alacritty"); mkdir -p "$(dirname "$f")" && if [ -f "$f" ] && [ "$(cat "$f")" != "$new" ]; then cp "$f" "$f.bak.$(date +%s)"; fi && printf '%s\n' "$new" > "$f"
CMDEOF
read -r -d '' HEALTH_ALACRITTY_DESKTOP <<'CMDEOF' || true
grep -qx "Exec=$HOME/.cargo/bin/alacritty" $HOME/.local/share/applications/Alacritty.desktop
CMDEOF
read -r -d '' HEALTH_ALACRITTY_COSMIC <<'CMDEOF' || true
grep -qF "Terminal: \"$HOME/.cargo/bin/alacritty\"" $HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/system_actions
CMDEOF

CMDS_alacrittydefault=(
	'mkdir -p $HOME/.local/share/applications $HOME/.local/share/icons/hicolor/scalable/apps'
	"$CMD_ALACRITTY_DESKTOP"
	'curl -fsSL https://raw.githubusercontent.com/alacritty/alacritty/master/extra/logo/alacritty-term.svg -o $HOME/.local/share/icons/hicolor/scalable/apps/Alacritty.svg'
	'! command -v update-desktop-database >/dev/null || update-desktop-database $HOME/.local/share/applications'
	'! command -v xdg-mime >/dev/null || xdg-mime default Alacritty.desktop x-scheme-handler/terminal application/x-terminal-emulator'
	"$CMD_ALACRITTY_COSMIC"
)
HEALTH_alacrittydefault=(
	"$HEALTH_ALACRITTY_DESKTOP"
	'[ -s $HOME/.local/share/icons/hicolor/scalable/apps/Alacritty.svg ]'
	'! command -v xdg-mime >/dev/null || [ "$(xdg-mime query default x-scheme-handler/terminal)" = Alacritty.desktop ]'
	"$HEALTH_ALACRITTY_COSMIC"
)
UPDATE_alacrittydefault=()
UNINSTALL_alacrittydefault=(
	'rm -f $HOME/.local/share/applications/Alacritty.desktop'
	'rm -f $HOME/.local/share/icons/hicolor/scalable/apps/Alacritty.svg'
	'! command -v update-desktop-database >/dev/null || update-desktop-database $HOME/.local/share/applications'
)
step alacrittydefault "Alacritty as default terminal" "alacritty" "cargo" "1"

CMDS_alacrittyxterm=(
	'update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$(getent passwd "$SUDO_USER" | cut -d: -f6)/.cargo/bin/alacritty" 60'
	'update-alternatives --set x-terminal-emulator "$(getent passwd "$SUDO_USER" | cut -d: -f6)/.cargo/bin/alacritty"'
)
HEALTH_alacrittyxterm=(
	'[ "$(readlink -f /usr/bin/x-terminal-emulator)" = "$HOME/.cargo/bin/alacritty" ]'
)
UPDATE_alacrittyxterm=()
UNINSTALL_alacrittyxterm=(
	'update-alternatives --remove x-terminal-emulator "$(getent passwd "$SUDO_USER" | cut -d: -f6)/.cargo/bin/alacritty"'
)
step alacrittyxterm "Alacritty as x-terminal-emulator" "alacritty" "cargo" "0"

# ===========================================================================
# desktop steps (GNOME): best-effort, no health checks, skip with -ignore desktop
# ===========================================================================

GNOME_SESSION='DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus '

read -r -d '' DESKTOP_SWITCH_WINDOWS <<CMDEOF || true
${GNOME_SESSION}gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
CMDEOF
read -r -d '' DESKTOP_SWITCH_WINDOWS_BACK <<CMDEOF || true
${GNOME_SESSION}gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"
CMDEOF
read -r -d '' DESKTOP_SWITCH_APPS <<CMDEOF || true
${GNOME_SESSION}gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
CMDEOF
read -r -d '' DESKTOP_SWITCH_APPS_BACK <<CMDEOF || true
${GNOME_SESSION}gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"
CMDEOF

CMDS_desktopworkspaces=(
	"${GNOME_SESSION}gsettings set org.gnome.shell.app-switcher current-workspace-only true"
	"${GNOME_SESSION}gsettings set org.gnome.shell.window-switcher current-workspace-only true"
	"${GNOME_SESSION}gsettings set org.gnome.mutter workspaces-only-on-primary false"
	"${GNOME_SESSION}gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces true"
	"$DESKTOP_SWITCH_WINDOWS"
	"$DESKTOP_SWITCH_WINDOWS_BACK"
	"$DESKTOP_SWITCH_APPS"
	"$DESKTOP_SWITCH_APPS_BACK"
)
HEALTH_desktopworkspaces=()
UPDATE_desktopworkspaces=()
UNINSTALL_desktopworkspaces=()
step desktopworkspaces "GNOME workspaces & Alt+Tab" "desktop" "" "1"

CMDS_desktopterminal=(
	"${GNOME_SESSION}gsettings set org.gnome.desktop.default-applications.terminal exec \$HOME/.cargo/bin/alacritty"
	"${GNOME_SESSION}gsettings set org.gnome.desktop.default-applications.terminal exec-arg -e"
)
HEALTH_desktopterminal=()
UPDATE_desktopterminal=()
UNINSTALL_desktopterminal=()
step desktopterminal "GNOME default terminal" "desktop alacritty" "" "1"

# ===========================================================================
# group dependency engine (mirrors the old lang/commands engine, in bash)
# ===========================================================================

declare -a ALL_GROUPS=()
declare -A GROUP_REQUIRES=()

build_registries() {
	local -A seen=()
	local id g r

	for id in "${STEP_IDS[@]}"; do
		for g in ${STEP_GROUPS[$id]}; do
			if [ -z "${seen[$g]:-}" ]; then
				seen[$g]=1
				ALL_GROUPS+=("$g")
			fi
		done
	done

	for id in "${STEP_IDS[@]}"; do
		for g in ${STEP_GROUPS[$id]}; do
			for r in ${STEP_REQUIRES[$id]}; do
				GROUP_REQUIRES[$g]="${GROUP_REQUIRES[$g]:-} $r"
			done
		done
	done
}

validate_groups() {
	if [ "${#IGNORE_GROUPS[@]}" -gt 0 ] && [ "${#ONLY_GROUPS[@]}" -gt 0 ]; then
		echo "fatal: -only and -ignore cannot be used together"
		exit 1
	fi

	local g known found id req
	for g in "${IGNORE_GROUPS[@]:-}" "${ONLY_GROUPS[@]:-}"; do
		[ -z "$g" ] && continue
		found=0
		for known in "${ALL_GROUPS[@]}"; do
			[ "$known" = "$g" ] && { found=1; break; }
		done
		if [ "$found" -ne 1 ]; then
			printf 'fatal: unknown group '"'"'%s'"'"'. available groups: %s\n' "$g" "$(join_comma "${ALL_GROUPS[@]}")"
			exit 1
		fi
	done

	for id in "${STEP_IDS[@]}"; do
		for req in ${STEP_REQUIRES[$id]}; do
			found=0
			for known in "${ALL_GROUPS[@]}"; do
				[ "$known" = "$req" ] && { found=1; break; }
			done
			if [ "$found" -ne 1 ]; then
				printf 'fatal: step '"'"'%s'"'"' requires unknown group '"'"'%s'"'"'\n' "${STEP_LABEL[$id]}" "$req"
				exit 1
			fi
		done
	done
}

declare -A CAUSE=()

expand_ignored() {
	CAUSE=()
	local g
	for g in "${IGNORE_GROUPS[@]:-}"; do
		[ -z "$g" ] && continue
		CAUSE[$g]="$g"
	done

	local changed=1 dep
	while [ "$changed" -eq 1 ]; do
		changed=0
		for g in "${ALL_GROUPS[@]}"; do
			[ -n "${CAUSE[$g]:-}" ] && continue
			for dep in ${GROUP_REQUIRES[$g]:-}; do
				if [ -n "${CAUSE[$dep]:-}" ]; then
					CAUSE[$g]="$dep"
					changed=1
					break
				fi
			done
		done
	done
}

ignored_reason() {
	local id="$1" g dep root
	for g in ${STEP_GROUPS[$id]}; do
		root="${CAUSE[$g]:-}"
		if [ -n "$root" ]; then
			if [ "$root" = "$g" ]; then
				echo "$g"
			else
				echo "$g needs $root"
			fi
			return 0
		fi
	done
	for dep in ${STEP_REQUIRES[$id]}; do
		if [ -n "${CAUSE[$dep]:-}" ]; then
			echo "needs $dep"
			return 0
		fi
	done
	return 1
}

declare -A CHOSEN=()

expand_selected() {
	local expand="$1"
	CHOSEN=()
	local -a pending=()
	local g dep

	for g in "${ONLY_GROUPS[@]:-}"; do
		[ -z "$g" ] && continue
		if [ -z "${CHOSEN[$g]:-}" ]; then
			CHOSEN[$g]="$g"
			pending+=("$g")
		fi
	done

	[ "$expand" != "1" ] && return 0

	if [ -z "${CHOSEN[$IMPLICIT_GROUP]:-}" ]; then
		CHOSEN[$IMPLICIT_GROUP]="$IMPLICIT_GROUP"
		pending+=("$IMPLICIT_GROUP")
	fi

	while [ "${#pending[@]}" -gt 0 ]; do
		g="${pending[0]}"
		pending=("${pending[@]:1}")
		for dep in ${GROUP_REQUIRES[$g]:-}; do
			if [ -z "${CHOSEN[$dep]:-}" ]; then
				CHOSEN[$dep]="$g"
				pending+=("$dep")
			fi
		done
	done
}

is_selected() {
	local id="$1" g
	for g in ${STEP_GROUPS[$id]}; do
		[ -n "${CHOSEN[$g]:-}" ] && return 0
	done
	return 1
}

pulled_in_groups() {
	local -a added=()
	local g o only_has
	for g in "${ALL_GROUPS[@]}"; do
		[ -z "${CHOSEN[$g]:-}" ] && continue
		only_has=0
		for o in "${ONLY_GROUPS[@]:-}"; do
			[ "$o" = "$g" ] && { only_has=1; break; }
		done
		[ "$only_has" -eq 0 ] && added+=("$g")
	done
	[ "${#added[@]}" -gt 0 ] && printf '%s\n' "${added[@]}"
	return 0
}

group_runs() {
	local group="$1" id
	for id in "${STEP_IDS[@]}"; do
		[ "${STEP_DISABLED[$id]}" = "1" ] && continue
		group_in_list "$group" "${STEP_GROUPS[$id]}" || continue

		if [ "${#ONLY_GROUPS[@]}" -gt 0 ]; then
			is_selected "$id" && return 0
			continue
		fi

		ignored_reason "$id" >/dev/null || return 0
	done
	return 1
}

# ---------------------------------------------------------------------------
# system layer
# ---------------------------------------------------------------------------

HOME_DIR=""

require_sudo() {
	if [ "$(id -u)" -ne 0 ]; then
		echo "fatal: you should use sudo"
		exit 1
	fi

	if [ -z "${SUDO_USER:-}" ]; then
		echo "fatal: SUDO_USER not set"
		exit 1
	fi

	if [ "$SUDO_USER" = "root" ]; then
		echo "fatal: do not run this as root"
		exit 1
	fi

	HOME_DIR="$(getent passwd "$SUDO_USER" | cut -d: -f6)"

	if [ -z "$HOME_DIR" ]; then
		echo "fatal: could not load home user: no passwd entry for $SUDO_USER"
		exit 1
	fi
}

run_as_home_silent() {
	runuser -u "$SUDO_USER" -- env HOME="$HOME_DIR" USER="$SUDO_USER" bash -c "$1" >/dev/null 2>&1
}

run_step_command() {
	local as_home="$1" cmd="$2" padding="$3" status

	if [ "$as_home" = "1" ]; then
		{ runuser -u "$SUDO_USER" -- env HOME="$HOME_DIR" USER="$SUDO_USER" bash -c "$cmd"; } 2>&1 |
			while IFS= read -r line || [ -n "$line" ]; do
				printf '%s%s%s%s\n' "$CLR_GRAY" "$padding" "$line" "$CLR_RESET"
			done
		status=${PIPESTATUS[0]}
	else
		{ bash -c "$cmd"; } 2>&1 |
			while IFS= read -r line || [ -n "$line" ]; do
				printf '%s%s%s%s\n' "$CLR_GRAY" "$padding" "$line" "$CLR_RESET"
			done
		status=${PIPESTATUS[0]}
	fi

	return "$status"
}

healthy() {
	local id="$1"
	local -n health_arr="HEALTH_${id}"
	local cmd
	for cmd in "${health_arr[@]:-}"; do
		[ -z "$cmd" ] && continue
		run_as_home_silent "$cmd" || return 1
	done
	return 0
}

# ---------------------------------------------------------------------------
# configs directory resolution
# ---------------------------------------------------------------------------

CONFIGS_BASE_DIR=""

has_configs() {
	[ -d "$1/configs" ]
}

resolve_configs_dir() {
	if [ -n "${CONFIG_MANAGER_DIR:-}" ]; then
		CONFIGS_BASE_DIR="$CONFIG_MANAGER_DIR"
		has_configs "$CONFIGS_BASE_DIR"
		return $?
	fi

	local cwd
	cwd="$(pwd)"
	if has_configs "$cwd"; then
		export CONFIG_MANAGER_DIR="$cwd"
		CONFIGS_BASE_DIR="$cwd"
		return 0
	fi

	CONFIGS_BASE_DIR="$HOME_DIR/.config-manager"
	has_configs "$CONFIGS_BASE_DIR"
}

# ===========================================================================
# the pipeline runner
# ===========================================================================

declare -a IGNORE_GROUPS=()
declare -a ONLY_GROUPS=()
COMMAND=""

run_pipeline() {
	local mode_name="$1" prefix="$2" skip_when_healthy="$3" skip_when_unhealthy="$4" \
		verify_after="$5" expand_selection="$6" reverse="$7"

	validate_groups

	expand_ignored
	expand_selected "$expand_selection"

	if [ "${#ONLY_GROUPS[@]}" -gt 0 ]; then
		local -a added=()
		mapfile -t added < <(pulled_in_groups)
		if [ "${#added[@]}" -gt 0 ]; then
			printf '%s-only %s also runs what it needs: %s%s\n\n' \
				"$CLR_CYAN" "$(join_comma "${ONLY_GROUPS[@]}")" "$(join_comma "${added[@]}")" "$CLR_RESET"
		fi
	fi

	require_sudo

	if group_runs "configs"; then
		if ! resolve_configs_dir; then
			printf "fatal: no configs directory found at '%s/configs'\n" "$CONFIGS_BASE_DIR"
			printf '       run %s from the repository, or point CONFIG_MANAGER_DIR at it:\n' "$mode_name"
			printf '       sudo CONFIG_MANAGER_DIR=/path/to/config-manager ./config-manager.sh %s\n' "$mode_name"
			exit 1
		fi
	fi

	local total=${#STEP_IDS[@]}
	local -a order=()
	local i
	if [ "$reverse" = "1" ]; then
		for ((i = total - 1; i >= 0; i--)); do order+=("$i"); done
	else
		for ((i = 0; i < total; i++)); do order+=("$i"); done
	fi

	local ran=0

	for i in "${order[@]}"; do
		local id="${STEP_IDS[$i]}"
		local position
		position=$(printf "Step %02d/%02d" "$((i + 1))" "$total")

		local -n step_cmds="${prefix}_${id}"
		if [ "${#step_cmds[@]}" -eq 0 ]; then
			continue
		fi

		[ "$ran" -gt 0 ] && echo
		ran=$((ran + 1))

		local label="${STEP_LABEL[$id]}"

		if [ "${STEP_DISABLED[$id]}" = "1" ]; then
			printf '%s%s %s(disabled)%s: %s%s\n' "$CLR_BLUE" "$position" "$CLR_DIM" "$CLR_BLUE" "$label" "$CLR_RESET"
			printf '  %sSkipping...%s\n' "$CLR_DIM" "$CLR_RESET"
			continue
		fi

		if [ "${#ONLY_GROUPS[@]}" -gt 0 ]; then
			if ! is_selected "$id"; then
				printf '%s%s %s(not selected)%s: %s%s\n' "$CLR_BLUE" "$position" "$CLR_DIM" "$CLR_BLUE" "$label" "$CLR_RESET"
				printf '  %sSkipping...%s\n' "$CLR_DIM" "$CLR_RESET"
				continue
			fi
		else
			local reason
			if reason=$(ignored_reason "$id"); then
				printf '%s%s %s(ignored: %s)%s: %s%s\n' "$CLR_BLUE" "$position" "$CLR_DIM" "$reason" "$CLR_BLUE" "$label" "$CLR_RESET"
				printf '  %sSkipping...%s\n' "$CLR_DIM" "$CLR_RESET"
				continue
			fi
		fi

		printf '%s%s: %s%s\n' "$CLR_BLUE" "$position" "$label" "$CLR_RESET"

		local -n health_cmds="HEALTH_${id}"

		if [ "${#health_cmds[@]}" -gt 0 ] && { [ "$skip_when_healthy" = "1" ] || [ "$skip_when_unhealthy" = "1" ]; }; then
			if healthy "$id"; then
				is_healthy=1
			else
				is_healthy=0
			fi

			if [ "$skip_when_healthy" = "1" ] && [ "$is_healthy" = "1" ]; then
				echo
				printf '  %sHealth checks:%s\n\n' "$CLR_CYAN" "$CLR_RESET"
				local hc
				for hc in "${health_cmds[@]}"; do
					printf '    %s$%s %s\n' "$CLR_YELLOW" "$CLR_RESET" "$hc"
					printf '      %sok%s\n' "$CLR_BGREEN" "$CLR_RESET"
				done
				echo
				printf '  %sSkipping %s (%s). already installed...%s\n' "$CLR_CYAN" "$position" "$label" "$CLR_RESET"
				continue
			fi

			if [ "$skip_when_unhealthy" = "1" ] && [ "$is_healthy" = "0" ]; then
				echo
				printf '  %sNot installed yet, nothing to update. Skipping...%s\n' "$CLR_CYAN" "$CLR_RESET"
				continue
			fi
		fi

		local abort_on_failure=0
		[ "$verify_after" = "1" ] && [ "${#health_cmds[@]}" -gt 0 ] && abort_on_failure=1

		local ci cmd status
		for ((ci = 0; ci < ${#step_cmds[@]}; ci++)); do
			cmd="${step_cmds[$ci]}"
			[ "$ci" -gt 0 ] && echo
			printf '  %s$%s %s\n' "$CLR_YELLOW" "$CLR_RESET" "$cmd"

			run_step_command "${STEP_ASHOME[$id]}" "$cmd" "    "
			status=$?

			if [ "$status" -eq 0 ]; then
				printf '    %sok%s\n' "$CLR_GREEN" "$CLR_RESET"
				continue
			fi

			printf '    %sfail: %d%s' "$CLR_RED" "$status" "$CLR_RESET"

			if [ "$abort_on_failure" = "1" ]; then
				echo
				printf '\n\n%s pipeline failed: %s (%s) failed with exit code %d for '"'"'%s'"'"'\n\n' \
					"$mode_name" "$position" "$label" "$status" "$cmd"
				exit 1
			fi

			printf '  ignoring...\n'
		done

		echo

		if [ "$verify_after" != "1" ]; then
			continue
		fi

		if [ "${#health_cmds[@]}" -eq 0 ]; then
			printf '%s  No health checks...%s\n' "$CLR_CYAN" "$CLR_RESET"
			continue
		fi

		printf '%s  Health checking...%s\n' "$CLR_CYAN" "$CLR_RESET"

		for hc in "${health_cmds[@]}"; do
			printf '    %s$%s %s\n' "$CLR_YELLOW" "$CLR_RESET" "$hc"

			run_as_home_silent "$hc"
			status=$?

			if [ "$status" -eq 0 ]; then
				printf '      %sok%s\n' "$CLR_BGREEN" "$CLR_RESET"
				continue
			fi

			printf '      %sfail: %d%s\n' "$CLR_BRED" "$status" "$CLR_RESET"
			printf '\n\n%s pipeline failed during health check: %s (%s) failed with exit code %d while health checking '"'"'%s'"'"'\n\n' \
				"$mode_name" "$position" "$label" "$status" "$hc"
			exit 1
		done
	done

	if [ "$ran" -eq 0 ]; then
		printf 'nothing to %s: no step defines %s commands\n' "$mode_name" "$mode_name"
	fi
}

cmd_install() { run_pipeline "install" "CMDS" "1" "0" "1" "1" "0"; }
cmd_update() { run_pipeline "update" "UPDATE" "0" "1" "1" "0" "0"; }
cmd_uninstall() { run_pipeline "uninstall" "UNINSTALL" "0" "0" "0" "0" "1"; }

cmd_list() {
	local total=${#STEP_IDS[@]} i=0 id disabled_suffix
	for id in "${STEP_IDS[@]}"; do
		i=$((i + 1))
		disabled_suffix=""
		[ "${STEP_DISABLED[$id]}" = "1" ] && disabled_suffix=" ${CLR_DIM}(disabled)${CLR_RESET}"

		printf '%s%02d/%02d%s %s%s\n' "$CLR_BLUE" "$i" "$total" "$CLR_RESET" "${STEP_LABEL[$id]}" "$disabled_suffix"
		printf '      %sgroups:%s %s\n' "$CLR_DIM" "$CLR_RESET" "$(join_comma ${STEP_GROUPS[$id]})"

		if [ -n "${STEP_REQUIRES[$id]}" ]; then
			printf '      %sneeds:%s %s\n' "$CLR_DIM" "$CLR_RESET" "$(join_comma ${STEP_REQUIRES[$id]})"
		fi

		local -n upd="UPDATE_${id}"
		local -n uninst="UNINSTALL_${id}"
		local -a supports=()
		[ "${#upd[@]}" -gt 0 ] && supports+=("update")
		[ "${#uninst[@]}" -gt 0 ] && supports+=("uninstall")

		if [ "${#supports[@]}" -gt 0 ]; then
			printf '      %ssupports:%s %s\n' "$CLR_DIM" "$CLR_RESET" "$(join_comma "${supports[@]}")"
		fi
	done
}

print_help() {
	printf 'Usage: %s [command]\n' "$0"
	printf '\n'
	printf 'Commands:\n'
	printf '  install     install tools to the system. (requires sudo)\n'
	printf '  update      pull and rebuild the tools installed from source. (requires sudo)\n'
	printf '  uninstall   remove what this tool created: symlinks, alternatives and desktop\n'
	printf '              entries. packages, toolchains and clones are left alone. (requires sudo)\n'
	printf '  list        print the pipeline without touching the system\n'
	printf '  version     show tool version\n'
	printf '  help        show this help message\n'
	printf '\n'
	printf 'Options:\n'
	printf '  -ignore <groups>  comma separated list of step groups to skip\n'
	printf '                    ignoring a group also skips every group that needs it\n'
	printf '  -only <groups>    comma separated list of step groups to run, skipping the rest\n'
	printf '                    install also runs whatever those groups need, so you do not\n'
	printf '                    have to know their dependencies. update and uninstall run\n'
	printf '                    exactly what you name. cannot be combined with -ignore\n'
	printf '\n'
	printf '  groups: %s\n' "$(join_comma "${ALL_GROUPS[@]}")"
}

# ---------------------------------------------------------------------------
# argument parsing
# ---------------------------------------------------------------------------

append_groups() {
	local target_name="$1" value="$2"
	local -n target="$target_name"
	local -a parts=()
	IFS=',' read -ra parts <<<"$value"
	local g
	for g in "${parts[@]}"; do
		g="${g#"${g%%[![:space:]]*}"}"
		g="${g%"${g##*[![:space:]]}"}"
		[ -n "$g" ] && target+=("$g")
	done
}

parse_args() {
	local -a args=("$@")
	local n=${#args[@]} i=0 arg value

	while [ "$i" -lt "$n" ]; do
		arg="${args[$i]}"
		i=$((i + 1))

		case "$arg" in
		-ignore=* | --ignore=*)
			append_groups IGNORE_GROUPS "${arg#*=}"
			continue
			;;
		-only=* | --only=*)
			append_groups ONLY_GROUPS "${arg#*=}"
			continue
			;;
		esac

		case "$arg" in
		-ignore | --ignore)
			if [ "$i" -ge "$n" ]; then
				echo "fatal: $arg expects a comma separated list of groups"
				exit 1
			fi
			value="${args[$i]}"
			i=$((i + 1))
			append_groups IGNORE_GROUPS "$value"
			;;
		-only | --only)
			if [ "$i" -ge "$n" ]; then
				echo "fatal: $arg expects a comma separated list of groups"
				exit 1
			fi
			value="${args[$i]}"
			i=$((i + 1))
			append_groups ONLY_GROUPS "$value"
			;;
		install | update | uninstall | list | version | help)
			COMMAND="$arg"
			;;
		*) ;;
		esac
	done

	[ -z "$COMMAND" ] && COMMAND="help"
}

main() {
	build_registries
	parse_args "$@"

	case "$COMMAND" in
	version) echo "$VERSION" ;;
	install) cmd_install ;;
	update) cmd_update ;;
	uninstall) cmd_uninstall ;;
	list) cmd_list ;;
	help) print_help ;;
	*)
		print_help
		exit 1
		;;
	esac
}

main "$@"
