# WSpaces Claude Integration

Integrate [WSpace](https://wspaces.app) with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — automate issue management, projects, and documents via GraphQL API.

## Installation

### Prerequisites
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- WSpace API Key (from WSpace Settings > Apps)

### One-command install

```bash
git clone git@github.com:trandactruong/wspaces-claude.git
bash wspaces-claude/wspace-install.sh
```

This installs two slash commands into Claude Code:
- `/wspace-setup` — Set up WSpace integration for the current project
- `/wspace-api` — Interact with the WSpace GraphQL API

## Usage

### 1. Project setup

Open Claude Code in your project:

```bash
cd my-project
claude
```

Run setup:

```
/wspace-setup
```

The setup wizard will:
- Prompt for your API key (or use an existing one)
- Connect and fetch workspace context (teams, workflows, labels, members)
- Create `.env` file with the API key
- Generate `CLAUDE.md` with project-specific defaults
- Update `.gitignore` to exclude `.env`
- Optionally enable auto-loop (5m / 10m / 30m)

### 2. WSpace API commands

```
/wspace-api context                          # View workspace info + scopes
/wspace-api workspaces                       # List all workspaces
/wspace-api issues list                      # List issues
/wspace-api issues get --team IVT --code 3   # Get issue details
/wspace-api issues create --title "Bug fix"  # Create a new issue
/wspace-api issues update --id <id> --priority HIGH
/wspace-api projects list                    # List projects
/wspace-api documents list                   # List documents
```

Once set up, you don't need to pass `--workspace` or `--team` — defaults are loaded from `CLAUDE.md`.

### 3. Auto-implement workflow

Enable auto-loop so the bot automatically processes assigned issues:

```
/loop 5m /wspace-api issues list
```

Or select an interval during `/wspace-setup`.

#### Flow

```
User assigns issue to Bot
  -> Backlog/Todo
  -> [Bot picks up] -> In Progress (comments implementation plan)
  -> [User responds via comment]
    -> approve       -> Bot implements  -> In Review (comments results)
    -> analyze more  -> Bot researches  -> In Progress (comments findings)
    -> feedback      -> Bot revises     -> In Progress (comments new plan)
    -> reject        -> Bot confirms    -> Backlog
    -> question      -> Bot answers     -> In Progress
  -> [User reviews In Review & completes manually]
```

#### How it works

1. **User creates an issue** on WSpace and **assigns it to the bot** (Claude Leader)
2. **Bot picks it up** — moves to In Progress, analyzes the task, comments the implementation plan
3. **User reviews the plan** — responds via comment on the issue:
   - "ok, go ahead" -> bot implements the code
   - "analyze section X further" -> bot does more research
   - "revise the plan" -> bot updates the approach
4. **Bot finishes implementation** -> comments results + moves to In Review
5. **User reviews** and completes manually

> The bot only processes issues explicitly assigned to it. It never self-assigns issues.

## File structure

After setup, your project will contain:

```
my-project/
  .env              # WSPACE_API_KEY
  .gitignore        # .env is excluded
  CLAUDE.md         # WSpace config defaults
```

Global Claude Code commands:

```
~/.claude/commands/
  wspace-api.md     # /wspace-api command
  wspace-setup.md   # /wspace-setup command
```

## Setting up on another machine

```bash
# On the new machine
npm install -g @anthropic-ai/claude-code
git clone git@github.com:trandactruong/wspaces-claude.git
bash wspaces-claude/wspace-install.sh

# Then in your project
claude
/wspace-setup
```

## API Reference

### Endpoint
- `https://api.wspaces.app/graphql`

### Authentication
Header: `x-api-key: <API_KEY>`

### Scopes
| Scope | Description |
|-------|-------------|
| ISSUES_READ / WRITE | Read/write issues |
| PROJECTS_READ / WRITE | Read/write projects |
| DOCUMENTS_READ / WRITE | Read/write documents |
| TEAMS_READ | Read teams |
| MEMBERS_READ | Read members |
| APPOINTMENTS_READ / WRITE | Read/write appointments |

### Priority levels
`NO_PRIORITY` | `URGENT` | `HIGH` | `MEDIUM` | `LOW`
