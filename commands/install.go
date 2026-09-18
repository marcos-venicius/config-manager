package commands

import (
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"github.com/marcos-venicius/config-manager/sys"
)

type step_t struct {
	label               string
	groups              []string // used by `-ignore`; a step is skipped when any of its groups is ignored
	requires            []string // groups this step needs; ignoring one of them skips this step too
	asHome              bool     // do not run commands as sudo
	disabled            bool
	commands            []string
	healthCheckCommands []string
	updateCommands      []string // `update`: refresh a step already installed, for the ones built from source
	uninstallCommands   []string // `uninstall`: undo what this step created, best effort
}

func allSteps() []step_t {
	return append(append([]step_t{}, installationSteps...), desktopSteps...)
}

// mode_t is what changes between install, update and uninstall: which commands to run,
// and what the health checks mean for them
type mode_t struct {
	name string

	commandsOf func(step_t) []string

	// install only: a step whose health checks already pass has nothing to do
	skipWhenHealthy bool
	// update only: a step that was never installed is not this command's job
	skipWhenUnhealthy bool
	// install and update: health checks run again afterwards and a failure aborts
	verifyAfter bool
	// install only: -only grows into the groups the named ones are built on. update and
	// uninstall act on what is already installed, so there they run exactly what is named
	// and uninstalling one group never drags its dependencies out with it
	expandSelection bool
	// uninstall undoes the pipeline, so it walks it backwards
	reverse bool
}

var (
	installMode = mode_t{
		name:            "install",
		commandsOf:      func(step step_t) []string { return step.commands },
		skipWhenHealthy: true,
		expandSelection: true,
		verifyAfter:     true,
	}

	updateMode = mode_t{
		name:              "update",
		commandsOf:        func(step step_t) []string { return step.updateCommands },
		skipWhenUnhealthy: true,
		verifyAfter:       true,
	}

	// nothing is verified here: after an uninstall the health checks are meant to fail,
	// and a command that has nothing left to remove is not an error either
	uninstallMode = mode_t{
		name:       "uninstall",
		commandsOf: func(step step_t) []string { return step.uninstallCommands },
		reverse:    true,
	}
)

// Groups returns every known step group, in pipeline order
func Groups() []string {
	seen := map[string]bool{}
	groups := []string{}

	for _, step := range allSteps() {
		for _, group := range step.groups {
			if !seen[group] {
				seen[group] = true
				groups = append(groups, group)
			}
		}
	}

	return groups
}

// groupRequires maps every group to the groups its steps depend on
func groupRequires() map[string][]string {
	requires := map[string][]string{}

	for _, step := range allSteps() {
		for _, group := range step.groups {
			requires[group] = append(requires[group], step.requires...)
		}
	}

	return requires
}

// expandIgnored grows the ignore list with every group that depends, directly or
// transitively, on an ignored one. The value is the ignored group that caused it,
// which is the group itself when it was ignored explicitly.
func expandIgnored(ignore []string) map[string]string {
	cause := map[string]string{}

	for _, group := range ignore {
		cause[group] = group
	}

	requires := groupRequires()

	for changed := true; changed; {
		changed = false

		for group, needed := range requires {
			if _, ignored := cause[group]; ignored {
				continue
			}

			for _, dependency := range needed {
				if _, ignored := cause[dependency]; ignored {
					cause[group] = dependency
					changed = true
					break
				}
			}
		}
	}

	return cause
}

// ignoredReason explains, for the step header, why a step is being skipped
func ignoredReason(step step_t, cause map[string]string) (string, bool) {
	// one of the step's own groups was ignored, either by hand or through a dependency
	for _, group := range step.groups {
		if root, ignored := cause[group]; ignored {
			if root == group {
				return group, true
			}

			return fmt.Sprintf("%s needs %s", group, root), true
		}
	}

	// the step itself depends on something that is ignored
	for _, group := range step.requires {
		if _, ignored := cause[group]; ignored {
			return fmt.Sprintf("needs %s", group), true
		}
	}

	return "", false
}

func validate(ignore, only []string) {
	groups := Groups()

	// -only is an allow list and -ignore a deny list; honouring both at once would
	// mean guessing which one the user meant for a group named in neither
	if len(ignore) > 0 && len(only) > 0 {
		fmt.Println("fatal: -only and -ignore cannot be used together")
		os.Exit(1)
	}

	for _, group := range append(append([]string{}, ignore...), only...) {
		if !slices.Contains(groups, group) {
			fmt.Printf("fatal: unknown group '%s'. available groups: %s\n", group, strings.Join(groups, ", "))
			os.Exit(1)
		}
	}

	// a typo in `requires` would silently never match anything, so catch it here
	for _, step := range allSteps() {
		for _, required := range step.requires {
			if !slices.Contains(groups, required) {
				fmt.Printf("fatal: step '%s' requires unknown group '%s'\n", step.label, required)
				os.Exit(1)
			}
		}
	}
}

func healthy(baseCmd sys.SysCmd, step step_t) bool {
	for _, healthCmd := range step.healthCheckCommands {
		if baseCmd.RunAsHome(healthCmd, nil, nil) != 0 {
			return false
		}
	}

	return true
}

// implicitGroup is pulled into every -only run. It brings the apt index, curl, wget and
// build-essential, which every other group assumes without saying so.
const implicitGroup = "base"

// expandSelected grows an -only list with everything the named groups need, transitively,
// so asking for one group does not require knowing what it is built on. The value is the
// group that pulled each one in, and equals the key for the ones named on the command line.
func expandSelected(only []string, expand bool) map[string]string {
	chosen := map[string]string{}
	pending := []string{}

	for _, group := range only {
		if _, ok := chosen[group]; !ok {
			chosen[group] = group
			pending = append(pending, group)
		}
	}

	if !expand {
		return chosen
	}

	if _, ok := chosen[implicitGroup]; !ok {
		chosen[implicitGroup] = implicitGroup
		pending = append(pending, implicitGroup)
	}

	requires := groupRequires()

	for len(pending) > 0 {
		group := pending[0]
		pending = pending[1:]

		for _, dependency := range requires[group] {
			if _, ok := chosen[dependency]; !ok {
				chosen[dependency] = group
				pending = append(pending, dependency)
			}
		}
	}

	return chosen
}

// pulledIn lists the groups a selection gained on top of what was asked for, in pipeline order
func pulledIn(only []string, chosen map[string]string) []string {
	added := []string{}

	for _, group := range Groups() {
		if _, ok := chosen[group]; ok && !slices.Contains(only, group) {
			added = append(added, group)
		}
	}

	return added
}

// groupRuns reports whether any step of a group is going to run under this selection
func groupRuns(group string, cause map[string]string, chosen map[string]string, only []string) bool {
	for _, step := range allSteps() {
		if step.disabled || !slices.Contains(step.groups, group) {
			continue
		}

		if len(only) > 0 {
			if isSelected(step, chosen) {
				return true
			}

			continue
		}

		if _, skipped := ignoredReason(step, cause); !skipped {
			return true
		}
	}

	return false
}

func isSelected(step step_t, chosen map[string]string) bool {
	for _, group := range step.groups {
		if _, ok := chosen[group]; ok {
			return true
		}
	}

	return false
}

func Install(ignore, only []string) { runPipeline(installMode, ignore, only) }

func Update(ignore, only []string) { runPipeline(updateMode, ignore, only) }

func Uninstall(ignore, only []string) { runPipeline(uninstallMode, ignore, only) }

// List prints the pipeline without touching the system
func List() {
	steps := allSteps()

	for index, step := range steps {
		disabled := ""
		if step.disabled {
			disabled = " \033[2;36m(disabled)\033[0m"
		}

		fmt.Printf("\033[0;34m%02d/%02d\033[0m %s%s\n", index+1, len(steps), step.label, disabled)
		fmt.Printf("      \033[2;36mgroups:\033[0m %s\n", strings.Join(step.groups, ", "))

		if len(step.requires) > 0 {
			fmt.Printf("      \033[2;36mneeds:\033[0m %s\n", strings.Join(step.requires, ", "))
		}

		supports := []string{}
		if len(step.updateCommands) > 0 {
			supports = append(supports, "update")
		}
		if len(step.uninstallCommands) > 0 {
			supports = append(supports, "uninstall")
		}

		if len(supports) > 0 {
			fmt.Printf("      \033[2;36msupports:\033[0m %s\n", strings.Join(supports, ", "))
		}
	}
}

func runPipeline(mode mode_t, ignore, only []string) {
	validate(ignore, only)

	steps := allSteps()
	total := len(steps)

	order := make([]int, total)
	for i := range order {
		if mode.reverse {
			order[i] = total - 1 - i
		} else {
			order[i] = i
		}
	}

	cause := expandIgnored(ignore)
	chosen := expandSelected(only, mode.expandSelection)

	if len(only) > 0 {
		if added := pulledIn(only, chosen); len(added) > 0 {
			fmt.Printf("\033[0;36m-only %s also runs what it needs: %s\033[0m\n\n", strings.Join(only, ","), strings.Join(added, ", "))
		}
	}

	baseCmd := sys.Command()

	// checked up front: finding this out from a failing `test -e` after the pipeline has
	// already spent twenty minutes building helix is not a useful way to learn it
	if groupRuns(configsGroup, cause, chosen, only) {
		if dir, ok := resolveConfigsDir(baseCmd.HomeDir()); !ok {
			fmt.Printf("fatal: no configs directory found at '%s'\n", filepath.Join(dir, "configs"))
			fmt.Printf("       run %s from the repository, or point CONFIG_MANAGER_DIR at it:\n", mode.name)
			fmt.Printf("       sudo CONFIG_MANAGER_DIR=/path/to/config-manager config-manager %s\n", mode.name)
			os.Exit(1)
		}
	}

	ran := 0

	for _, index := range order {
		step := steps[index]
		stepCommands := mode.commandsOf(step)

		// update and uninstall are only defined for some of the steps
		if len(stepCommands) == 0 {
			continue
		}

		if ran > 0 {
			fmt.Println()
		}
		ran++

		position := fmt.Sprintf("Step %02d/%02d", index+1, total)

		if step.disabled {
			fmt.Printf("\033[0;34m%s \033[2;36m(disabled)\033[0;34m: %s\033[0m\n", position, step.label)
			fmt.Printf("  \033[2;36mSkipping...\033[0m\n")
			continue
		}

		if len(only) > 0 {
			if !isSelected(step, chosen) {
				fmt.Printf("\033[0;34m%s \033[2;36m(not selected)\033[0;34m: %s\033[0m\n", position, step.label)
				fmt.Printf("  \033[2;36mSkipping...\033[0m\n")
				continue
			}
		} else if reason, ok := ignoredReason(step, cause); ok {
			fmt.Printf("\033[0;34m%s \033[2;36m(ignored: %s)\033[0;34m: %s\033[0m\n", position, reason, step.label)
			fmt.Printf("  \033[2;36mSkipping...\033[0m\n")
			continue
		}

		fmt.Printf("\033[0;34m%s: %s\033[0m\n", position, step.label)

		// install skips what is already there; update skips what was never installed,
		// because bringing it up from nothing is the install command's job
		if len(step.healthCheckCommands) > 0 && (mode.skipWhenHealthy || mode.skipWhenUnhealthy) {
			isHealthy := healthy(baseCmd, step)

			if mode.skipWhenHealthy && isHealthy {
				fmt.Println()
				fmt.Printf("  \033[0;36mHealth checks:\033[0m\n\n")

				for _, healthCmd := range step.healthCheckCommands {
					fmt.Printf("    \033[0;33m$\033[0m %s\n", healthCmd)
					fmt.Printf("      \033[1;32mok\033[0m\n")
				}

				fmt.Println()
				fmt.Printf("  \033[0;36mSkipping %s (%s). already installed...\033[0m\n", position, step.label)
				continue
			}

			if mode.skipWhenUnhealthy && !isHealthy {
				fmt.Println()
				fmt.Printf("  \033[0;36mNot installed yet, nothing to update. Skipping...\033[0m\n")
				continue
			}
		}

		// without health checks there is nothing to tell a real failure from a no-op,
		// so those steps are best effort. uninstall is best effort by design.
		abortOnFailure := mode.verifyAfter && len(step.healthCheckCommands) > 0

		for i, cmd := range stepCommands {
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
				continue
			}

			fmt.Printf("    \033[0;31mfail: %d\033[0m", exitCode)

			if abortOnFailure {
				fmt.Println()
				fmt.Printf("\n\n%s pipeline failed: %s (%s) failed with exit code %d for '%s'\n\n", mode.name, position, step.label, exitCode, cmd)
				os.Exit(1)
			}

			fmt.Println("  ignoring...")
		}

		fmt.Println()

		if !mode.verifyAfter {
			continue
		}

		if len(step.healthCheckCommands) == 0 {
			fmt.Printf("\033[0;36m  No health checks...\033[0m\n")
			continue
		}

		fmt.Printf("\033[0;36m  Health checking...\033[0m\n")

		for _, healthCmd := range step.healthCheckCommands {
			fmt.Printf("    \033[0;33m$\033[0m %s\n", healthCmd)

			exitCode := baseCmd.RunAsHome(healthCmd, nil, nil)

			if exitCode == 0 {
				fmt.Println("      \033[1;32mok\033[0m")
				continue
			}

			fmt.Printf("      \033[1;31mfail: %d\033[0m\n", exitCode)
			fmt.Printf("\n\n%s pipeline failed during health check: %s (%s) failed with exit code %d while health checking '%s'\n\n", mode.name, position, step.label, exitCode, healthCmd)
			os.Exit(1)
		}
	}

	if ran == 0 {
		fmt.Printf("nothing to %s: no step defines %s commands\n", mode.name, mode.name)
	}
}

func stdoutStderrPrinter(padding string) *func(string) {
	printer := func(text string) {
		fmt.Printf("\033[2;38m%s%s\033[0m\n", padding, text)
	}

	return &printer
}
