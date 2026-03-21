package main

import (
	"fmt"
	"os"

	"github.com/marcos-venicius/config-manager/commands"
)

func main() {
	// bake it during build with commit and date
	const VERSION = "2.3.1"

	args := CreateArgumentsParser().Parse()

	switch true {
	case args.version:
		fmt.Println(VERSION)
	case args.help:
		args.Help()
	case args.install:
		commands.Install()
	default:
		args.Help()
		os.Exit(1)
	}
}
