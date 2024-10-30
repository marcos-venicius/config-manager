package main

import (
	"flag"
	"fmt"
	"os"
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
}
