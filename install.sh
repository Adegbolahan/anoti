#!/bin/bash
# Install script for Claude Code Scaffolder
# Adds aliases to your shell config so you can run commands from anywhere

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAFFOLD_SCRIPT="$SCRIPT_DIR/scaffold-project.py"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Claude Code Scaffolder - Installation               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detect shell
SHELL_CONFIG=""
SHELL_NAME=""

if [ -n "$ZSH_VERSION" ]; then
    SHELL_NAME="zsh"
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_NAME="bash"
    if [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    else
        SHELL_CONFIG="$HOME/.bashrc"
    fi
else
    # Try to detect from SHELL env var
    case "$SHELL" in
        */zsh)
            SHELL_NAME="zsh"
            SHELL_CONFIG="$HOME/.zshrc"
            ;;
        */bash)
            SHELL_NAME="bash"
            if [ -f "$HOME/.bash_profile" ]; then
                SHELL_CONFIG="$HOME/.bash_profile"
            else
                SHELL_CONFIG="$HOME/.bashrc"
            fi
            ;;
        *)
            echo -e "${YELLOW}⚠️  Could not detect shell. Please add aliases manually.${NC}"
            exit 1
            ;;
    esac
fi

echo -e "Detected shell: ${GREEN}$SHELL_NAME${NC}"
echo -e "Config file: ${GREEN}$SHELL_CONFIG${NC}"
echo ""

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}⚠️  Python 3 not found. Please install Python 3 first.${NC}"
    exit 1
fi

# Aliases to add
ALIASES="
# Claude Code Scaffolder Aliases
# Added by install.sh on $(date)
alias claude-scaffold='python3 $SCAFFOLD_SCRIPT'
alias claude-scaffold-minimal='python3 $SCAFFOLD_SCRIPT --minimal'
"

# Check if aliases already exist
if grep -q "Claude Code Scaffolder Aliases" "$SHELL_CONFIG" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Aliases already exist in $SHELL_CONFIG${NC}"
    echo ""
    read -p "Do you want to update them? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}ℹ️  Installation cancelled.${NC}"
        exit 0
    fi

    # Remove old aliases
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' '/# Claude Code Scaffolder Aliases/,/^$/d' "$SHELL_CONFIG"
    else
        # Linux
        sed -i '/# Claude Code Scaffolder Aliases/,/^$/d' "$SHELL_CONFIG"
    fi
fi

# Add aliases
echo "$ALIASES" >> "$SHELL_CONFIG"

echo -e "${GREEN}✅ Aliases added to $SHELL_CONFIG${NC}"
echo ""
echo -e "${BLUE}Available commands:${NC}"
echo -e "  ${GREEN}claude-scaffold <path>${NC}          - Full scaffolding"
echo -e "  ${GREEN}claude-scaffold-minimal <path>${NC}  - Minimal scaffolding"
echo ""
echo -e "${YELLOW}⚡ To use the commands in this terminal, run:${NC}"
echo -e "  ${GREEN}source $SHELL_CONFIG${NC}"
echo ""
echo -e "${YELLOW}💡 Or open a new terminal window.${NC}"
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Installation complete! 🎉                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
