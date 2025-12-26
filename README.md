# Git Repos Viewer

A Windows batch script that generates an HTML page listing all git repositories across WSL and SSH hosts. Click any repo to open it directly in VS Code Remote.

## Features

- **WSL Repos**: Scans `~/` in WSL for git repositories
- **SSH Repos**: Scans all hosts from Windows SSH config (`~/.ssh/config`)
- **Tree Structure**: Displays repos in a tree format showing nested directories
- **One-Click Open**: Links open VS Code Remote (WSL or SSH) in a new window
- **Offline Detection**: Shows which SSH hosts are unreachable

## Usage

Double-click `git-repos.bat` on Windows Desktop.

## Output Example

```
~/ (WSL)
+-- bible-stories
+-- algo_trading
+-- stt-children
:   +-- _clones
:   :   +-- hero-logo-navbar
:   :   +-- transcribe-progress-timestamps

SSH: mixtiles
~/
+-- album-maker
:   +-- _clones
:   :   +-- train-aesthetics
```

## Requirements

- Windows with WSL installed
- VS Code with Remote extensions (WSL, SSH)
- SSH config at `%USERPROFILE%\.ssh\config`

## How It Works

1. Uses `wsl.exe` to find `.git` directories in WSL home
2. Reads SSH hosts from Windows SSH config using `findstr`
3. Uses Windows SSH to scan each remote host (5 second timeout)
4. Generates HTML with `vscode://vscode-remote/` links
5. Opens in default browser

## Notes

- SSH uses Windows SSH (not WSL) since config/keys are on Windows
- Uses ASCII tree characters (`+--`, `:`) to avoid encoding issues
- Uses `call` and `timeout` to ensure proper command synchronization
