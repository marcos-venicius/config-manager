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
}

func checkConfigInstalled(configuration configuration) bool {
	fmt.Printf("[%s] at [%s]\n", configuration.name, configuration.installAt)

	fmt.Println("- checking...")

	fullpath := configuration.ExpandPath()

	return utils.PathExists(fullpath)
}

func checkIsASymlink(configuration configuration) bool {
	fullpath := configuration.ExpandPath()

	info, err := os.Lstat(fullpath)

	if err != nil {
		panic(err)
	}

	return info.Mode()&fs.ModeSymlink != 0
}

func install(configuration configuration) error {
	fmt.Println("- installing...")

	appLocation, err := utils.GetEnv(utils.APP_LOCATION_ENV_NAME)

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
			isSymLink := checkIsASymlink(configuration)

			if isSymLink {
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
