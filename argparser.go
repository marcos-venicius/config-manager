package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/marcos-venicius/config-manager/commands"
)

type arguments_t struct {
	programName string

	install, version, help bool

	ignore []string
}

func CreateArgumentsParser() *arguments_t {
	return &arguments_t{
		programName: "",
		install:     false,
		version:     false,
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

		if value, ok := strings.CutPrefix(strings.TrimPrefix(arg, "-"), "-ignore="); ok {
			a.addIgnored(value)
			continue
		}

		switch arg {
		case "-ignore", "--ignore":
			value, ok := shift()

			if !ok {
				fmt.Printf("fatal: %s expects a comma separated list of groups\n", arg)
				os.Exit(1)
			}

			a.addIgnored(value)
		case "install":
			a.install = true
		case "version":
			a.version = true
		case "help":
			a.help = true
		}
	}

	// force help when "help" or no command is informed
	if a.help || (!a.version && !a.install) {
		a.help = true
		a.version = false
		a.install = false
	}

	return a
}

func (a *arguments_t) addIgnored(value string) {
	for _, group := range strings.Split(value, ",") {
		if group = strings.TrimSpace(group); group != "" {
			a.ignore = append(a.ignore, group)
		}
	}
}

func (a *arguments_t) Help() {
	fmt.Printf("Usage: %s [command]\n", a.programName)
	fmt.Printf("\n")
	fmt.Printf("Commands:\n")
	fmt.Printf("  install     install tools to the system. (requires sudo)\n")
	fmt.Printf("  version     show tool version\n")
	fmt.Printf("  help        show this help message\n")
	fmt.Printf("\n")
	fmt.Printf("Options:\n")
	fmt.Printf("  -ignore <groups>  comma separated list of step groups to skip during install\n")
	fmt.Printf("                    groups: %s\n", strings.Join(commands.Groups(), ", "))
}
