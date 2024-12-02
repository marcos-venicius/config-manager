package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/marcos-venicius/config-manager/commands"
	"github.com/marcos-venicius/config-manager/utils"
)

func main() {
	const VERSION = "2.2.0"

	update := flag.Bool("update", false, "update all settings")
	install := flag.Bool("install", false, "install all settings")
	version := flag.Bool("version", false, "view current version")

	flag.Parse()

	switch true {
	case *version:
		fmt.Println(VERSION)
	case *update:
		utils.ErrorPrinter(commands.Update())
	case *install:
		utils.ErrorPrinter(commands.Install())
	default:
		flag.Usage()
		fmt.Printf("\nUse one of the options above\n")
		os.Exit(1)
	}
}
