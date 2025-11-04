# Installation Guide

## Quick Install (One Command)

```bash
cd $HOME/Code/getting-started-claude && ./install.sh
```

Then reload your shell:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

**That's it!** You can now run `claude-scaffold` from anywhere.

---

## What Gets Installed

The install script adds these aliases to your shell config:

```bash
# Claude Code Scaffolder Aliases
alias claude-scaffold='python3 $HOME/Code/getting-started-claude/scaffold-project.py'
alias claude-scaffold-minimal='python3 $HOME/Code/getting-started-claude/scaffold-project.py --minimal'
```

**File modified:**
- `~/.zshrc` (for zsh)
- `~/.bashrc` or `~/.bash_profile` (for bash)

---

## Usage After Installation

### Create a new project (full scaffolding)

```bash
claude-scaffold ~/Code/my-new-project
```

### Create a minimal project (just essentials)

```bash
claude-scaffold-minimal ~/Code/my-new-project
```

### From anywhere in your filesystem

```bash
# Works from any directory
cd ~/Documents
claude-scaffold ~/Code/another-project

cd /tmp
claude-scaffold ~/Code/yet-another-project
```

---

## Manual Installation

If you prefer manual setup or the install script doesn't work:

### For Zsh (macOS default)

Add to `~/.zshrc`:

```bash
# Claude Code Scaffolder
alias claude-scaffold='python3 $HOME/Code/getting-started-claude/scaffold-project.py'
alias claude-scaffold-minimal='python3 $HOME/Code/getting-started-claude/scaffold-project.py --minimal'
```

Then: `source ~/.zshrc`

### For Bash

Add to `~/.bashrc` or `~/.bash_profile`:

```bash
# Claude Code Scaffolder
alias claude-scaffold='python3 $HOME/Code/getting-started-claude/scaffold-project.py'
alias claude-scaffold-minimal='python3 $HOME/Code/getting-started-claude/scaffold-project.py --minimal'
```

Then: `source ~/.bashrc`

### For Fish Shell

Add to `~/.config/fish/config.fish`:

```fish
# Claude Code Scaffolder
alias claude-scaffold='python3 $HOME/Code/getting-started-claude/scaffold-project.py'
alias claude-scaffold-minimal='python3 $HOME/Code/getting-started-claude/scaffold-project.py --minimal'
```

Then: `source ~/.config/fish/config.fish`

---

## Verify Installation

Check if the aliases work:

```bash
# Should show the help message
claude-scaffold --help
```

Or test with a dummy directory:

```bash
claude-scaffold /tmp/test-project
cd /tmp/test-project
ls -la
```

---

## Uninstall

To remove the aliases:

### For Zsh/Bash

Edit `~/.zshrc` or `~/.bashrc` and remove these lines:

```bash
# Claude Code Scaffolder Aliases
# Added by install.sh on ...
alias claude-scaffold='...'
alias claude-scaffold-minimal='...'
```

Then reload: `source ~/.zshrc`

### Or Use Sed

```bash
# For macOS
sed -i '' '/# Claude Code Scaffolder Aliases/,/^$/d' ~/.zshrc

# For Linux
sed -i '/# Claude Code Scaffolder Aliases/,/^$/d' ~/.zshrc
```

---

## Troubleshooting

### "command not found: claude-scaffold"

**Cause:** Shell config not reloaded

**Fix:**
```bash
source ~/.zshrc  # or ~/.bashrc
```

Or open a new terminal window.

### "python3: command not found"

**Cause:** Python 3 not installed

**Fix (macOS):**
```bash
brew install python3
```

**Fix (Ubuntu/Debian):**
```bash
sudo apt update && sudo apt install python3
```

### Aliases not working after restart

**Cause:** Shell config file not being sourced on startup

**Fix:** Make sure your shell loads the config file. Add to `~/.zshenv`:

```bash
source ~/.zshrc  # or ~/.bashrc
```

### Install script says "already exists"

**Cause:** Aliases already in shell config

**Options:**
1. Run install script and choose "y" to update
2. Manually edit shell config to update paths
3. Leave as-is if working correctly

---

## Testing Installation

Run this one-liner to test everything:

```bash
claude-scaffold /tmp/test-claude-scaffold && \
cd /tmp/test-claude-scaffold && \
ls -la && \
cat CLAUDE.md | head -20 && \
cd - && \
rm -rf /tmp/test-claude-scaffold && \
echo "✅ Installation working correctly!"
```

---

## Next Steps After Installation

See [QUICK-REFERENCE.md](QUICK-REFERENCE.md) for:
- Common tasks
- Priority checklist
- Pattern doc priorities
- Troubleshooting

Or see [README.md](README.md) for complete documentation.
