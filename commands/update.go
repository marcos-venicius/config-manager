package commands

import "github.com/marcos-venicius/config-manager/utils"

func Update() error {
	err := utils.EnsureAppFolderExists()

	if err != nil {
		return err
	}

  return nil
}
