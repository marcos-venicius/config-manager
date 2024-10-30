package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/marcos-venicius/config-manager/commands"
	"github.com/marcos-venicius/config-manager/utils"
)

func main() {
	const VERSION = "1.0.0"

	update := flag.Bool("update", false, "update all settings")
	install := flag.Bool("install", false, "install all settings")
	version := flag.Bool("version", false, "view current version")

	flag.Parse()

	if !*update && !*install && !*version {
		flag.Usage()
		fmt.Printf("\nUse one of the options above\n")
		os.Exit(1)
	}

	if *version {
		fmt.Println(VERSION)
		os.Exit(0)
	}

	if *update {
		utils.ErrorPrinter(commands.Update())
		os.Exit(0)
	}

	if *install {
		utils.ErrorPrinter(commands.Install())
		os.Exit(0)
	}
}
