package lang

type step_t struct {
	os          string // for now, only "linux"
	label       string
	groups      []string
	requires    []string
	health_code string // based on the `os` it can be bash, powershell, etc. for now, only bash because there is only linux support.
	up_code     string // based on the `os` it can be bash, powershell, etc. for now, only bash because there is only linux support.
	down_code   string // based on the `os` it can be bash, powershell, etc. for now, only bash because there is only linux support.
}
