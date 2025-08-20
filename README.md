# Claude Code Setup Guide

This guide explains how to install and use `@anthropic-ai/claude-code`.

## 1. Node.js Requirement

The package requires **Node.js ≥ 18.0.0** (as of Aug 20, 2025).  
If your current version is older, update it using the steps below.

```bash
# Check versions
node -v
npm -v

# Remove old Node.js and npm (if installed via apt)
sudo apt remove -y nodejs npm

# Install NodeSource Node.js 18 (or newer)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node -v
npm -v
````

## 2. Install the Package

You can install the package in two ways.

### Option A: Global Install

```bash
sudo npm install -g @anthropic-ai/claude-code
```

### Option B: Local Install (Recommended)

Run directly with `npx`:

```bash
npx @anthropic-ai/claude-code
```

Or install locally in your project:

```bash
npm install @anthropic-ai/claude-code --save-dev
```

Then run:

```bash
npx claude-code
```

## 3. VS Code Extension

To use Claude Code in VS Code, install the extension:

* **Extension Name**: Claude Code for VSCode
* **Marketplace Link**: https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code
