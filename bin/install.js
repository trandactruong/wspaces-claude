#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const os = require("os");

const COMMANDS_DIR = path.join(os.homedir(), ".claude", "commands");
const SOURCE_DIR = path.join(__dirname, "..", "commands");

console.log("=== WSpace Integration for Claude Code ===\n");

// Create commands directory
fs.mkdirSync(COMMANDS_DIR, { recursive: true });

// Copy command files
const files = fs.readdirSync(SOURCE_DIR).filter((f) => f.endsWith(".md"));

for (const file of files) {
  const src = path.join(SOURCE_DIR, file);
  const dest = path.join(COMMANDS_DIR, file);
  fs.copyFileSync(src, dest);
  const name = file.replace(".md", "");
  console.log(`[✓] Installed: /${name}`);
}

console.log(`
=== Installation Complete ===

Commands available in Claude Code:
  /wspace-setup          Setup WSpace for current project
  /wspace-setup <key>    Setup with specific API key
  /wspace-api            Query WSpace API (issues, projects, docs)

Quick start:
  1. cd into your project
  2. export WSPACE_API_KEY="sk_live_your_key" && claude
  3. Run: /wspace-setup
`);
