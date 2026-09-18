package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/marcos-venicius/config-manager/commands"
)

type arguments_t struct {
	programName string

	command string

	ignore []string
	only   []string
}

func CreateArgumentsParser() *arguments_t {
	return &arguments_t{
		programName: "",
		command:     "",
	}
}

func (a *arguments_t) Parse() *arguments_t {
	argv := os.Args
	argc := len(argv)
	index := 0

	shift := func() (string, bool) {
		if index >= argc {
			return "", false
		}

		arg := argv[index]

		index++

		return arg, true
	}

	a.programName, _ = shift()

	for {
		arg, ok := shift()

		if !ok {
			break
		}

		if value, ok := cutFlag(arg, "ignore"); ok {
			a.ignore = appendGroups(a.ignore, value)
			continue
		}

		if value, ok := cutFlag(arg, "only"); ok {
			a.only = appendGroups(a.only, value)
			continue
		}

		switch arg {
		case "-ignore", "--ignore":
			value, ok := shift()

			if !ok {
				fmt.Printf("fatal: %s expects a comma separated list of groups\n", arg)
				os.Exit(1)
			}

			a.ignore = appendGroups(a.ignore, value)
		case "-only", "--only":
			value, ok := shift()

			if !ok {
				fmt.Printf("fatal: %s expects a comma separated list of groups\n", arg)
				os.Exit(1)
			}

			a.only = appendGroups(a.only, value)
		case "install", "update", "uninstall", "list", "version", "help":
			a.command = arg
		}
	}

	// force help when no command is informed
	if a.command == "" {
		a.command = "help"
	}

	return a
}

// cutFlag matches both "-name=value" and "--name=value"
func cutFlag(arg, name string) (string, bool) {
	for _, prefix := range []string{"-" + name + "=", "--" + name + "="} {
		if value, ok := strings.CutPrefix(arg, prefix); ok {
			return value, true
		}
	}

	return "", false
}

func appendGroups(groups []string, value string) []string {
	for _, group := range strings.Split(value, ",") {
		if group = strings.TrimSpace(group); group != "" {
			groups = append(groups, group)
		}
	}

	return groups
}

func (a *arguments_t) Help() {
	fmt.Printf("Usage: %s [command]\n", a.programName)
	fmt.Printf("\n")
	fmt.Printf("Commands:\n")
	fmt.Printf("  install     install tools to the system. (requires sudo)\n")
	fmt.Printf("  update      pull and rebuild the tools installed from source. (requires sudo)\n")
	fmt.Printf("  uninstall   remove what this tool created: symlinks, alternatives and desktop\n")
	fmt.Printf("              entries. packages, toolchains and clones are left alone. (requires sudo)\n")
	fmt.Printf("  list        print the pipeline without touching the system\n")
	fmt.Printf("  version     show tool version\n")
	fmt.Printf("  help        show this help message\n")
	fmt.Printf("\n")
	fmt.Printf("Options:\n")
	fmt.Printf("  -ignore <groups>  comma separated list of step groups to skip\n")
	fmt.Printf("                    ignoring a group also skips every group that needs it\n")
	fmt.Printf("  -only <groups>    comma separated list of step groups to run, skipping the rest\n")
	fmt.Printf("                    install also runs whatever those groups need, so you do not\n")
	fmt.Printf("                    have to know their dependencies. update and uninstall run\n")
	fmt.Printf("                    exactly what you name. cannot be combined with -ignore\n")
	fmt.Printf("\n")
	fmt.Printf("  groups: %s\n", strings.Join(commands.Groups(), ", "))
}
