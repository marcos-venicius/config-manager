package commands

// gsettings writes to the user's dconf, so it needs the user's session bus
const gnomeSession = "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus "

// desktop preferences (GNOME). they only make sense on a desktop session,
// so failures are ignored (no health checks) and the whole group can be skipped with `-ignore desktop`
var desktopSteps = []step_t{
	{
		label:  "GNOME workspaces & Alt+Tab",
		groups: []string{"desktop"},
		asHome: true,
		commands: []string{
			// alt+tab / super+tab only show what is in the current workspace
			gnomeSession + "gsettings set org.gnome.shell.app-switcher current-workspace-only true",
			gnomeSession + "gsettings set org.gnome.shell.window-switcher current-workspace-only true",
			// workspaces span every monitor, not only the primary one
			gnomeSession + "gsettings set org.gnome.mutter workspaces-only-on-primary false",
			// dock only shows apps from the current workspace
			gnomeSession + "gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces true",
			// alt+tab switches windows, super+tab switches applications
			gnomeSession + `gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"`,
			gnomeSession + `gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"`,
			gnomeSession + `gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"`,
			gnomeSession + `gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"`,
		},
	},
	{
		label:  "GNOME default terminal",
		groups: []string{"desktop", "alacritty"},
		asHome: true,
		commands: []string{
			// used by the "launch terminal" shortcut and by apps asking for the default terminal
			gnomeSession + "gsettings set org.gnome.desktop.default-applications.terminal exec $HOME/.cargo/bin/alacritty",
			gnomeSession + "gsettings set org.gnome.desktop.default-applications.terminal exec-arg -e",
		},
	},
}
