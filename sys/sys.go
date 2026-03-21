package sys

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
	"os/user"
	"strconv"
	"syscall"
)

type SysCmd struct {
	uid      uint32
	gid      uint32
	homeDir  string
	username string
}

func Command() SysCmd {
	if os.Geteuid() != 0 {
		fmt.Println("fatal: you should use sudo")
		os.Exit(1)
	}

	username := os.Getenv("SUDO_USER")
	if username == "" {
		fmt.Println("fatal: SUDO_USER not set")
		os.Exit(1)
	}

	usr, err := user.Lookup(username)
	if err != nil {
		fmt.Printf("fatal: could not load home user: %s\n", err)
		os.Exit(1)
	}

	if usr.Username == "root" {
		fmt.Println("fatal: do not run this as root")
		os.Exit(1)
	}

	uid, _ := strconv.Atoi(usr.Uid)
	gid, _ := strconv.Atoi(usr.Gid)

	return SysCmd{
		uid:      uint32(uid),
		gid:      uint32(gid),
		homeDir:  usr.HomeDir,
		username: usr.Username,
	}
}

func (s SysCmd) newHomeCmd(command string) *exec.Cmd {
	cmd := exec.Command("bash", "-c", command)

	cmd.Env = append(os.Environ(),
		"HOME="+s.homeDir,
		"USER="+s.username,
	)

	cmd.SysProcAttr = &syscall.SysProcAttr{
		Credential: &syscall.Credential{
			Uid: s.uid,
			Gid: s.gid,
		},
	}

	return cmd
}

func (s SysCmd) newRootCmd(command string) *exec.Cmd {
	return exec.Command("bash", "-c", command)
}

func run(cmd *exec.Cmd, stdoutPrinter, stderrPrinter *func(string)) int {
	stdout, _ := cmd.StdoutPipe()
	stderr, _ := cmd.StderrPipe()

	if err := cmd.Start(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if stdoutPrinter != nil {
		go scanPipe(stdout, *stdoutPrinter)
	}

	if stderrPrinter != nil {
		go scanPipe(stderr, *stderrPrinter)
	}

	cmd.Wait()
	return cmd.ProcessState.ExitCode()
}

func scanPipe(pipe io.Reader, printer func(string)) {
	scanner := bufio.NewScanner(pipe)
	for scanner.Scan() {
		printer(scanner.Text())
	}
}

func (s SysCmd) RunAsHome(command string, stdoutPrinter, stderrPrinter *func(string)) int {
	cmd := s.newHomeCmd(command)
	return run(cmd, stdoutPrinter, stderrPrinter)
}

func (s SysCmd) RunAsSudo(command string, stdoutPrinter, stderrPrinter *func(string)) int {
	cmd := s.newRootCmd(command)
	return run(cmd, stdoutPrinter, stderrPrinter)
}
