package commands

import (
	"fmt"

	"github.com/marcos-venicius/config-manager/utils"
)

func Update() error {
	appLocation, err := utils.GetEnv(utils.APP_FOLDER_LOCATION)

	stdout, stderr, err := utils.Exec(fmt.Sprintf("cd \"%s\" && git fetch && git fetch --prune && git pull && go install", appLocation))

	if err != nil {
		fmt.Printf(stderr)
	} else {
		fmt.Printf(stdout)
	}

	return nil
}
