# WSpace Project Setup

One-command setup to integrate the current project with WSpace.

## Steps

### 1. Resolve API Key

- Check env var `WSPACE_API_KEY` first
- If not set, check if `$ARGUMENTS` contains an API key (starts with `sk_live_`)
- If neither, ask user via AskUserQuestion for their WSpace API key
- **Do NOT create `.env` file** — API key is set per terminal session to support multiple bot instances

### 2. Detect Endpoint

- Endpoint: `https://api.wspaces.app/graphql`
- Test with a simple query to verify connectivity

### 3. Fetch Workspace Context

Query the API with:
```
{ appContext { workspace { id name url logo timezone large_company created_at updated_at } teams { id name identifier icon color } workflows { id name color type } labels { id name color } project_statuses { id name color type } members { id email full_name username } scopes } }
```

If error "requires API key authentication" (user-level key), query `workspaces` instead and ask user to pick one.

### 4. Detect Bot Identity

Query `me` to resolve the bot's own identity:
```
{ me { id email full_name } }
```
- Verify email ends in `@bot.wspaces.app`
- Store the bot's `id` and `full_name` for display in summary
- The `me` query is preferred over email pattern matching — it directly returns the authenticated bot's identity

### 5. Generate `CLAUDE.md`

**Skip if `CLAUDE.md` already exists** and contains the same workspace ID.
- Read existing `CLAUDE.md`, check for `Workspace ID: \`<ID>\``
- If match → skip writing, print "CLAUDE.md already configured for this workspace"
- If no match or file doesn't exist → create/update with fetched data
- If user passes `--force` in arguments → always overwrite

**Do NOT hardcode bot ID** — instead include instructions to query `me` at runtime.

```markdown
# WSpace API Defaults

When running `/wspace-api` commands, use these defaults unless overridden:

## Connection
- **Endpoint:** `https://api.wspaces.app/graphql`
- **API Key:** env `WSPACE_API_KEY` (set per terminal session, NOT from .env file)

## Bot Identity (Dynamic)

**Do NOT hardcode bot ID.** At startup or first API call, query `me` to resolve own identity:
\`\`\`graphql
{ me { id email full_name } }
\`\`\`
Then query `appContext` for workspace data:
\`\`\`graphql
{ appContext { workspace { id name url } members { id email full_name username } scopes } }
\`\`\`
Cache the bot's `id` for the session. The `me` query is preferred over email pattern matching when multiple bots exist.

Multiple Claude Code instances can run in the same project folder, each with a different `WSPACE_API_KEY`. Each instance auto-detects its own bot identity.

## Workspace: <NAME>
- **Workspace ID:** `<ID>`
- **Workspace URL:** `<URL>`

## Teams
(list all teams)

## Workflows
(list all workflows)

## Labels
(list all labels)

## Project Statuses
(list all project statuses)

## Members
(list all members)

## Comments API
# Create comment
mutation(\$input: CreateCommentInput!) { createComment(createInput: \$input) }
# Query comments
{ comments(getInput: { issue_id: "<ID>", workspace_id: "<WS_ID>" }) { id content created_by user { full_name email } created_at } }

## Auto-implement Workflow

**IMPORTANT: Only process issues assigned to THIS bot's own member ID.** Query `me` first to discover own identity. Never self-assign unassigned issues.

### Phase 0: Resolve bot identity
1. Query `{ me { id email full_name } }` using current `WSPACE_API_KEY`
2. Verify email ends in `@bot.wspaces.app`
3. Cache `bot_id` for the session

### Phase 1: Pick up new issues
1. Fetch issues assigned to `bot_id` in Backlog/Todo
2. Move to In Progress
3. Analyze task -> comment implementation plan on issue

### Phase 2: Respond to user comments on In Progress issues
1. Fetch issues assigned to `bot_id` in In Progress
2. Query comments, find latest non-bot comment (created_by != bot_id)
3. Read and understand comment intent (do NOT use keyword matching):
   - Approve -> implement code -> comment results -> In Review
   - More analysis -> analyze -> comment findings (stay In Progress)
   - Feedback -> revise plan -> comment new plan (stay In Progress)
   - Reject -> confirm -> Backlog
   - Question -> answer via comment (stay In Progress)
4. Skip if latest comment is from bot (waiting for user)

## Schema Notes
- `UserEntity` uses `full_name` and `username` (not `first_name`/`last_name`)
- `IssueLabelEntity` uses `id` and `label_id` (not `name`/`color`)
```

### 6. Show startup instructions

Tell the user how to launch Claude Code with their API key:
```
export WSPACE_API_KEY="<key>" && claude
```

For multiple bots on the same project, open separate terminals:
```
# Terminal 1
export WSPACE_API_KEY="sk_live_app1_key" && claude

# Terminal 2
export WSPACE_API_KEY="sk_live_app2_key" && claude
```

### 7. Ask about Auto-loop

Ask user via AskUserQuestion:
- "Do you want to enable auto-implement loop?" with options:
  - "Yes - 5 min"
  - "Yes - 10 min"
  - "Yes - 30 min"
  - "No, I will run manually"

If yes, create a CronCreate with the selected interval using this prompt:

```
Run two phases using env WSPACE_API_KEY:

Phase 0 - Resolve identity: Query `{ me { id email full_name } }` to get bot's own member ID.

Phase 1 - New issues: Query issues assigned to bot_id in Backlog/Todo.
For each: move to In Progress, analyze task, comment plan on issue.

Phase 2 - Respond to comments: Query issues assigned to bot_id in In Progress.
For each: query comments, find latest non-bot comment (created_by != bot_id).
Read and understand the comment intent (do NOT use keyword matching):
- Approve -> implement code, comment results, move to In Review
- More analysis -> analyze further, comment findings (stay In Progress)
- Feedback -> update plan, comment new plan (stay In Progress)
- Reject -> confirm, move to Backlog
- Question -> answer via comment (stay In Progress)
Skip if latest comment is from bot (waiting for user).

If nothing to process: "No new issues to process."
```

### 8. Display Summary

Show the user:
- Workspace name and URL
- Bot identity: name and email (detected from API key)
- Number of teams, workflows, labels, members
- Scopes checklist (enabled/disabled)
- Files created: `CLAUDE.md`, `.gitignore` (if modified)
- How to launch: `export WSPACE_API_KEY="<key>" && claude`
- Auto-loop status (on/off, interval, job ID)
- Quick reference commands

## Input

$ARGUMENTS
