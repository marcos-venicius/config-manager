package utils

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

const (
	APP_FOLDER_ENV_NAME   = "CM_APP_FOLDER"
	APP_LOCATION_ENV_NAME = "CM_APP_LOCATION"
)

func GetEnv(key string) (string, error) {
	result := os.Getenv(key)

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
	appLocation, err := GetEnv(APP_FOLDER_ENV_NAME)

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

// TODO: prevent against shell injection attacks on env vars, create a sanitizer
func Exec(command string) (string, string, error) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer

	cmd := exec.Command("bash", "-c", command)

	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()

	return stdout.String(), stderr.String(), err
}

func ParseHomePath(fullpath string) string {
  if fullpath[0:2] == "~/" {
    result, err := os.UserHomeDir()

    if err != nil {
      panic(err)
    }

    return result + fullpath[1:]
  }

  return fullpath
}
