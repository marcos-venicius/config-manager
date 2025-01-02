package commands

import (
	"fmt"
	"io/fs"
	"os"
	"path"
	"strings"

	"github.com/marcos-venicius/config-manager/utils"
)

type configuration struct {
	name      string
	installAt string
}

func (c *configuration) ExpandPath() string {
	return utils.ParseHomePath(path.Join(c.installAt, c.name))
}

var configurations = []configuration{
	{
		name:      "alacritty",
		installAt: "~/.config/",
	},
	{
		name:      "nvim",
		installAt: "~/.config/",
	},
	{
		name: "helix",
		installAt: "~/.config/",
	},
	{
		name:      ".tmux.conf",
		installAt: "~/",
	},
	{
		name:      ".vimrc",
		installAt: "~/",
	},
	{
		name:      ".zshrc",
		installAt: "~/",
	},
	{
		name:      ".gitconfig",
		installAt: "~/",
	},
}

func checkConfigInstalled(configuration configuration) bool {
	fmt.Printf("[%s] at [%s]\n", configuration.name, configuration.installAt)

	fmt.Println("- checking...")

	fullpath := configuration.ExpandPath()

	return utils.PathExists(fullpath)
}

func checkInstallSource(configuration configuration) (bool, error) {
	appLocation, err := utils.GetEnv(utils.APP_FOLDER_LOCATION)

	if err != nil {
		return false, err
	}

	fullpath := configuration.ExpandPath()

	info, err := os.Lstat(fullpath)

	if err != nil {
		panic(err)
	}

	isSymLink := info.Mode()&fs.ModeSymlink != 0

	if !isSymLink {
		return false, nil
	}

	link, err := os.Readlink(fullpath)
	sourceLocation := path.Join(appLocation, "configs", configuration.name)

	if err != nil {
		return false, nil
	}

	return link == sourceLocation, nil
}

func install(configuration configuration) error {
	fmt.Println("- installing...")

	appLocation, err := utils.GetEnv(utils.APP_FOLDER_LOCATION)

	if err != nil {
		return err
	}

	fullpath := configuration.ExpandPath()
	sourceLocation := path.Join(appLocation, "configs", configuration.name)

	stdout, stderr, err := utils.Exec(fmt.Sprintf("ln -s \"%s\" \"%s\"", sourceLocation, fullpath))

	if len(stdout) > 0 {
		fmt.Printf(stdout)
	}

	if len(stderr) > 0 {
		fmt.Printf(stderr)
	}

	if err == nil && len(stderr) == 0 {
		fmt.Println("- installed successfully")
	}

	return err
}

func forceInstallation(configuration configuration) {
	fmt.Println("- removing old installation")

	fullpath := configuration.ExpandPath()

	err := os.RemoveAll(fullpath)

	if err != nil {
		panic(err)
	}

	install(configuration)
}

func askForceInstallation(configuration configuration) {
	var response string

	fmt.Printf("do you want to force the installation? ")
	fmt.Scan(&response)

	response = strings.TrimSpace(strings.ToLower(response))

	switch response {
	case "y", "yes", "yep", "of course", "yeah", "yup", "sim", "s", "si", "oui":
		forceInstallation(configuration)
	default:
		fmt.Println("- tool not installed")
		break
	}
}

func Install() error {
	for _, configuration := range configurations {
		exists := checkConfigInstalled(configuration)

		if exists {
			installationSource, err := checkInstallSource(configuration)

			if err != nil {
				return err
			}

			if installationSource {
				fmt.Println("- already installed")
			} else {
				fmt.Println("! installed from a different source")
				askForceInstallation(configuration)
			}
		} else {
			err := install(configuration)

			if err != nil {
				return err
			}
		}

		fmt.Println()
	}

	return nil
}
