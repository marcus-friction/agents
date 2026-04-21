#!/usr/bin/env bash

# Agent Ecosystem Installation Script
# This script downloads the .agents directory, AGENTS.md, and CLAUDE.md from the remote repository
# into the current directory.

set -e

REPO_URL="https://github.com/marcus-friction/agents.git"
TMP_DIR=$(mktemp -d)

# Cleanup on exit
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v git &> /dev/null; then
    echo "Error: git is not installed but is required to download the ecosystem."
    exit 1
fi

echo "=> Cloning Agent Ecosystem into a temporary directory..."
if ! git clone --depth 1 "$REPO_URL" "$TMP_DIR" > /dev/null; then
    echo "Error: Failed to clone the repository."
    exit 1
fi

echo "=> Installing .agents/ rules and skills..."
if [ -d "$TMP_DIR/.agents" ]; then
    cp -af "$TMP_DIR/.agents" ./
    echo "=> Registering skills with Claude Code..."
    mkdir -p .claude
    ln -sfn ../.agents/skills .claude/skills 2>/dev/null || { rm -rf .claude/skills; cp -R .agents/skills .claude/skills; }
else
    echo "Warning: .agents directory not found in the remote repository."
fi

echo "=> Installing AGENTS.md router..."
if [ -f "$TMP_DIR/AGENTS.md" ]; then
    cp -af "$TMP_DIR/AGENTS.md" ./
fi

echo "=> Installing CLAUDE.md..."
if [ -f "$TMP_DIR/CLAUDE.md" ]; then
    if [ -f "CLAUDE.md" ]; then
        echo "   CLAUDE.md already exists locally. Appending agent configuration..."
        # Append only if it isn't already referencing AGENTS.md
        if ! grep -q "@AGENTS.md" "CLAUDE.md"; then
            echo "" >> CLAUDE.md
            cat "$TMP_DIR/CLAUDE.md" >> CLAUDE.md
            echo "   [Included] Added @AGENTS.md reference."
        else
            echo "   [Skipped] CLAUDE.md already includes the @AGENTS.md configuration."
        fi
    else
        cp -af "$TMP_DIR/CLAUDE.md" ./
    fi
fi

echo "=> Installing dependency setup script..."
if [ -f "$TMP_DIR/install-dependencies.sh" ]; then
    cp -af "$TMP_DIR/install-dependencies.sh" ./
    chmod +x ./install-dependencies.sh
    echo ""
    echo "=> Bootstrapping system dependencies..."
    if ! ./install-dependencies.sh; then
        echo "=> System dependency installation aborted or failed. Exiting ecosystem setup."
        exit 1
    fi
fi

echo ""
echo "=> Installation Complete!"
echo "   To initialize the ecosystem, open your AI chat and prompt:"
echo "     - @start-project   (for a brand new codebase or idea)"
echo "     - @onboard-project (to integrate into an existing repository)"

