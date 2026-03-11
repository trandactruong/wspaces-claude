#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const os = require("os");
const { execSync } = require("child_process");

const PKG = require("../package.json");
const COMMANDS_DIR = path.join(os.homedir(), ".claude", "commands");
const SOURCE_DIR = path.join(__dirname, "..", "commands");

function isNewer(latest, current) {
  const a = latest.split(".").map(Number);
  const b = current.split(".").map(Number);
  for (let i = 0; i < 3; i++) {
    if ((a[i] || 0) > (b[i] || 0)) return true;
    if ((a[i] || 0) < (b[i] || 0)) return false;
  }
  return false;
}

function checkForUpdate() {
  try {
    const latest = execSync("npm view wspaces-claude version", {
      encoding: "utf8",
      timeout: 5000,
    }).trim();
    if (latest && isNewer(latest, PKG.version)) {
      console.log(`[!] Update available: ${PKG.version} → ${latest}`);
      console.log(`    Run: npx wspaces-claude@latest\n`);
      return latest;
    }
  } catch {
    // Offline or not published yet — skip
  }
  return null;
}

function installCommands() {
  fs.mkdirSync(COMMANDS_DIR, { recursive: true });

  const files = fs.readdirSync(SOURCE_DIR).filter((f) => f.endsWith(".md"));

  for (const file of files) {
    const src = path.join(SOURCE_DIR, file);
    const dest = path.join(COMMANDS_DIR, file);
    fs.copyFileSync(src, dest);
    const name = file.replace(".md", "");
    console.log(`[✓] Installed: /${name}`);
  }
}

// Main
console.log(`=== WSpace Integration for Claude Code v${PKG.version} ===\n`);

checkForUpdate();
installCommands();

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
