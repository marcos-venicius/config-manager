package utils

import (
	"errors"
	"fmt"
	"os"
	"strings"
)

const (
	APP_FOLDER_ENV_NAME = "CM_APP_FOLDER"
)

func getEnv(key string) (string, error) {
	result := os.Getenv(APP_FOLDER_ENV_NAME)

	if result == "" {
		return "", errors.New(fmt.Sprintf("env var \"%s\" not found", key))
	}

	return result, nil
}

func ErrorPrinter(err error) {
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func GetAppLocation() (string, error) {
	return getEnv(APP_FOLDER_ENV_NAME)
}

func PathExists(path string) bool {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return false
	}

	return true
}

// CreateFolder creates a folder and ensure that the whole path exists, if not, it will be created
func CreateFolder(path string) error {
	split := strings.Split(path, "/")

  for i := 0; i < len(split); i++ {
		path = strings.Join(split[:i+1], "/")

    if path == "" {
      continue
    }

		if !PathExists(path) {
			err := os.Mkdir(path, 0777)

			if err != nil {
				return err
			}
		}
	}

	return nil
}

func EnsureAppFolderExists() error {
	appLocation, err := GetAppLocation()

	if err != nil {
		return err
	}

	if !PathExists(appLocation) {
		err := CreateFolder(appLocation)

		if err != nil {
			return err
		}
	}

	return nil
}
