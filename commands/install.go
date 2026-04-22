package commands

import (
	"fmt"
	"os"

	"github.com/marcos-venicius/config-manager/sys"
)

type step_t struct {
	label               string
	asHome              bool // do not run commands as sudo
	disabled 					  bool
	commands            []string
	healthCheckCommands []string
}

func Install() {
	baseCmd := sys.Command()

	for stepIndex, step := range installationSteps {
		if stepIndex > 0 {
			fmt.Println()
		}

		if step.disabled {
			fmt.Printf("\033[0;34mStep %02d \033[2;36m(disabled)\033[0;34m: %s\033[0m\n", stepIndex+1, step.label)
			fmt.Printf("  \033[2;36mSkipping...\033[0m\n")
			continue
		}

		fmt.Printf("\033[0;34mStep %02d: %s\033[0m\n", stepIndex+1, step.label)

		if len(step.healthCheckCommands) > 0 {
			for _, healthCmd := range step.healthCheckCommands {
				exitCode := baseCmd.RunAsHome(healthCmd, nil, nil)

				if exitCode != 0 {
					goto install_step_tools
				}
			}

			fmt.Println()
			fmt.Printf("  \033[0;36mHealth checks:\033[0m\n\n")

			for _, healthCmd := range step.healthCheckCommands {
				fmt.Printf("    \033[0;33m$\033[0m %s\n", healthCmd)
				fmt.Printf("      \033[1;32mok\033[0m\n")
			}

			fmt.Println()
			fmt.Printf("  \033[0;36mSkipping step %02d (%s). already installed...\033[0m\n", stepIndex+1, step.label)
			continue
		}

	install_step_tools:
		for i, cmd := range step.commands {
			if i > 0 {
				fmt.Println()
			}

			fmt.Printf("  \033[0;33m$\033[0m %s\n", cmd)

			exitCode := 0

			if step.asHome {
				exitCode = baseCmd.RunAsHome(cmd, stdoutStderrPrinter("    "), stdoutStderrPrinter("    "))
			} else {
				exitCode = baseCmd.RunAsSudo(cmd, stdoutStderrPrinter("    "), stdoutStderrPrinter("    "))
			}

			if exitCode == 0 {
				fmt.Println("    \033[0;32mok\033[0m")
			} else {
				fmt.Printf("    \033[0;31mfail: %d\033[0m", exitCode)

				if len(step.healthCheckCommands) > 0 {
					fmt.Println()
					fmt.Printf("\n\ninstallation pipeline faild: step %02d (%s) failed with exit code %d for '%s'\n\n", stepIndex+1, step.label, exitCode, cmd)
					os.Exit(1)
				} else {
					fmt.Println("  ignoring...")
				}
			}
		}

		fmt.Println()

		if len(step.healthCheckCommands) > 0 {
			fmt.Printf("\033[0;36m  Health checking...\033[0m\n")

			for _, healthCmd := range step.healthCheckCommands {
				fmt.Printf("    \033[0;33m$\033[0m %s\n", healthCmd)

				exitCode := baseCmd.RunAsHome(healthCmd, nil, nil)

				if exitCode == 0 {
					fmt.Println("      \033[1;32mok\033[0m")
				} else {
					fmt.Printf("      \033[1;31mfail: %d\033[0m\n", exitCode)

					fmt.Printf("\n\ninstallation pipeline faild during helth check: step %02d (%s) failed with exit code %d while health checking '%s'\n\n", stepIndex+1, step.label, exitCode, healthCmd)
					os.Exit(1)
				}
			}
		} else {
			fmt.Printf("\033[0;36m  No health checks...\033[0m\n")
		}
	}
}

func stdoutStderrPrinter(padding string) *func(string) {
	printer := func(text string) {
		fmt.Printf("\033[2;38m%s%s\033[0m\n", padding, text)
	}

	return &printer
}
