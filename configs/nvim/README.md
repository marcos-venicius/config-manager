# Nvim configs

- LSP
- Eslint
- Multi Cursors
- Auto Completion
- Rose Pine theme
- Fuzzy Find
- File Manager
- Tree Sitter
- Prettier
- Comment
- Git Signs
- Random themes (vscode, papercolor)
- Trouble

![image](https://github.com/user-attachments/assets/ec8c4d12-ef15-40c2-98eb-0d9258be8516)
![image](https://github.com/user-attachments/assets/559aca72-3380-4dab-8539-b3c32677b3d6)

## Setting up

You should install `ripgrep`:

```bash
sudo apt-get install ripgrep -y
```

To use `prettier`, you should install it:

```bash
npm install -g prettier
```

To use `go`, you should install `gopls`:

```bash
go install -v golang.org/x/tools/gopls@latest
```

If you want to exclude some folders from live grep, for example: `node_modules`, you can configure
it by creating a file `~/.gitignore`, and adding your excluded files and folders like:

```
node_modules
*.lock
```

And, after this, configuring it to git:

```bash
git config --global core.excludesFile ~/.gitignore
```

## Selecting random theme by hand

Everytime you open your nvim a random theme will be selected, but if you want to randomize it again:

```
:RandomTheme
```
