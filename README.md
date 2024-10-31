# Config manager

This is my tools config manager

## Installing

**Requirements:**

1. Have golang installed

**Steps:**

Clone the repository:

```bash
git clone https://github.com/marcos-venicius/config-manager ~/.config-manager
```

Go to the folder:

```bash
cd ~/.config-manager
```

Install the binary:

```bash
go install
```

Install the configs:

```bash
CM_APP_LOCATION="$HOME/.config-manager" CM_APP_FOLDER="$CM_APP_LOCATION/data" config-manager -install
```

**If you don't want to use my `.zshrc` file, you need to setup these env vars after the install**


```bash
export CM_APP_LOCATION="$HOME/.config-manager"
export CM_APP_FOLDER="$CM_APP_LOCATION/data"
```
