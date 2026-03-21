package main

import (
	"fmt"
	"os"
)

type arguments_t struct {
	programName string

	install, version, help bool
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

		switch arg {
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

func (a *arguments_t) Help() {
	fmt.Printf("Usage: %s [command]\n", a.programName)
	fmt.Printf("\n")
	fmt.Printf("Commands:\n")
	fmt.Printf("  install     install tools to the system. (requires sudo)\n")
	fmt.Printf("  version     show tool version\n")
	fmt.Printf("  help        show this help message\n")
}
