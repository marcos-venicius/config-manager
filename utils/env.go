package utils

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

const (
	APP_FOLDER_LOCATION = "CM_APP_FOLDER_LOCATION"
)

var defaultEnv = map[string]string{
	"CM_APP_FOLDER_LOCATION": ParseHomePath("~/.config-manager/"),
}

func GetEnv(key string) (string, error) {
	result := os.Getenv(key)

	if result == "" {
		if result, ok := defaultEnv[key]; ok {
			return result, nil
		}

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

func PathExists(path string, isFolder bool) bool {
	stat, err := os.Stat(path)

	if os.IsNotExist(err) {
		return false
	}

	if isFolder {
		return stat.IsDir()
	}

	return !stat.IsDir()
}

// CreateFolder creates a folder and ensure that the whole path exists, if not, it will be created
func CreateFolder(path string) error {
	split := strings.Split(path, "/")

	for i := range split {
		path = strings.Join(split[:i+1], "/")

		if path == "" {
			continue
		}

		if !PathExists(path, true) {
			err := os.Mkdir(path, 0777)

			if err != nil {
				return err
			}
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

// TODO: prevent against shell injection attacks on env vars, create a sanitizer
func SysExec(command string, loggingPadding string) int {
	cmd := exec.Command("bash", "-c", command)

	stdout, err := cmd.StdoutPipe()

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	stderr, err := cmd.StderrPipe()

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	err = cmd.Start()

	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	stdoutScanner := bufio.NewScanner(stdout)
	stderrScanner := bufio.NewScanner(stderr)

	go func() {
		for stdoutScanner.Scan() {
			// TODO: pad left so it stays inside the context of the command
			fmt.Printf("\033[2;38m%s%s\033[0m\n", loggingPadding, stdoutScanner.Text())
		}
	}()

	go func() {
		for stderrScanner.Scan() {
			// TODO: pad left so it stays inside the context of the command
			fmt.Printf("\033[2;38m%s%s\033[0m\n", loggingPadding, stderrScanner.Text())
		}
	}()

	cmd.Wait()

	return cmd.ProcessState.ExitCode()
}

// TODO: prevent against shell injection attacks on env vars, create a sanitizer
func SimpleExec(command string) int {
	cmd := exec.Command("bash", "-c", command)

	cmd.Run()

	return cmd.ProcessState.ExitCode()
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
