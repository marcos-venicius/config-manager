package main

import (
	"fmt"
	"os"

	"github.com/marcos-venicius/config-manager/commands"
)

func main() {
	// bake it during build with commit and date
	const VERSION = "3.1.0"

	args := CreateArgumentsParser().Parse()

	switch args.command {
	case "version":
		fmt.Println(VERSION)
	case "install":
		commands.Install(args.ignore, args.only)
	case "update":
		commands.Update(args.ignore, args.only)
	case "uninstall":
		commands.Uninstall(args.ignore, args.only)
	case "list":
		commands.List()
	case "help":
		args.Help()
	default:
		args.Help()
		os.Exit(1)
	}
}
