#!/bin/bash
# WSpace Integration Installer for Claude Code
# Usage: curl -s <url> | bash  OR  bash wspace-install.sh

set -e

COMMANDS_DIR="$HOME/.claude/commands"

echo "=== WSpace Integration for Claude Code ==="
echo ""

# Check Claude Code
if ! command -v claude &> /dev/null; then
  echo "[!] Claude Code not found. Install it first:"
  echo "    npm install -g @anthropic-ai/claude-code"
  exit 1
fi

echo "[✓] Claude Code detected"

# Create commands directory
mkdir -p "$COMMANDS_DIR"

# Download/copy command files
echo "[*] Installing custom commands..."

# wspace-api.md
cat > "$COMMANDS_DIR/wspace-api.md" << 'WSPACE_API_EOF'
# Auth

- Resolve `API_KEY`: check env `WSPACE_API_KEY`, or ask user via AskUserQuestion.
- Resolve `ENDPOINT`: try `https://api.wspaces.app/graphql`, fallback `http://localhost:8060/graphql`.
- All curl requests include: `-H "Content-Type: application/json" -H "x-api-key: <API_KEY>"`.

# Parse

Format: `<command> [action] [options]`

Commands:
- `context` — get workspace info + API key scopes
- `workspaces` — list all workspaces
- `issues <list|get|create|update|delete>` — CRUD issues
- `projects <list|get|create|update|delete>` — CRUD projects
- `documents <list|get|create|update|delete>` — CRUD documents

If empty or unclear, use AskUserQuestion to ask which command to run.

---

# Command: context

Query workspace context and scopes for the current API key.

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"{ appContext { workspace { id name url logo timezone large_company created_at updated_at } teams { id name identifier icon color } workflows { id name color type } labels { id name color } project_statuses { id name color type } members { id email full_name username } scopes } }"}'
```

If error "requires API key authentication" → this is a user-level key, fallback to `workspaces` command.

**Output format:**

Workspace table, then scopes checklist — mark enabled scopes with [x]:

```
- [x] ISSUES_READ        — Read issues
- [x] ISSUES_WRITE       — Write issues
- [ ] PROJECTS_READ      — Read projects
- [ ] PROJECTS_WRITE     — Write projects
- [ ] DOCUMENTS_READ     — Read documents
- [ ] DOCUMENTS_WRITE    — Write documents
- [ ] TEAMS_READ         — Read teams
- [ ] MEMBERS_READ       — Read members
- [ ] APPOINTMENTS_READ  — Read appointments
- [ ] APPOINTMENTS_WRITE — Write appointments
- [ ] AI_ANALYZE         — AI analysis
- [ ] AI_SUGGEST         — AI suggestions
- [ ] AI_AUTO_ASSIGN     — AI auto-assignment
- [ ] AI_REPORTS         — AI reporting
- [ ] AI_WEBHOOKS        — AI webhooks
```

Then list teams as `[identifier] name`, members as `name <email>`.

---

# Command: workspaces

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"{ workspaces { id name url logo timezone large_company your_role created_at updated_at is_deleted } }"}'
```

Display as table: | ID | Name | URL | Role | Created |

---

# Command: issues

Options:
- `list` — `--workspace <id>` (required) `--team <id>` `--assignee <id>` `--project <id>` `--page <n>` `--limit <n>`
- `get` — `--url <workspace_url>` `--team <identifier>` `--code <number>`
- `create` — `--title <t>` `--workspace <id>` `--team <id>` `--workflow <id>` (required), `--description <t>` `--priority <P>` `--assignee <id>` `--project <id>` `--labels <id1,id2>` `--due <date>` (optional)
- `update` — `--id <id>` (required), `--title` `--description` `--workflow <id>` `--priority <P>` `--assignee <id>` `--project <id>` `--labels <id1,id2>` `--due <date>` (optional)
- `delete` — `--id <id>` (required)

If missing required fields, ask user via AskUserQuestion.

## issues list

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"{ issues(getInput: { workspace_id: \"<WS_ID>\", team_id: \"<TEAM>\", assignee_id: \"<ASSIGNEE>\", project_id: \"<PROJECT>\", page: <PAGE>, limit: <LIMIT> }) { items { id title code priority workflow_id project_id assignee_id due_date_at created_by created_at is_deleted labels { id label_id } } totalCount hasMore } }"}'
```

Remove null optional fields from input. Display: | Code | Title | Priority | Assignee | Due Date |

## issues get

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"{ issue(getInput: { workspace_url: \"<URL>\", team_identifier: \"<IDENT>\", issue_identifier: <CODE> }) { id title code description priority workflow_id project_id assignee_id due_date_at created_by created_at updated_at labels { id label_id } } }"}'
```

## issues create

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"mutation { createIssue(createInput: { title: \"<TITLE>\", workspace_id: \"<WS_ID>\", team_id: \"<TEAM_ID>\", workflow_id: \"<WORKFLOW_ID>\", priority: <PRIORITY>, description: \"<DESC>\", assignee_id: \"<ASSIGNEE>\", project_id: \"<PROJECT>\", label_ids: [\"<L1>\",\"<L2>\"], due_date_at: \"<DUE>\" }) { id title code priority created_at } }"}'
```

Remove null optional fields. Default priority: `NO_PRIORITY`.

## issues update

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"mutation { updateIssue(updateInput: { id: \"<ID>\", title: \"<TITLE>\", description: \"<DESC>\", workflow_id: \"<WF>\", priority: <P>, assignee_id: \"<A>\", project_id: \"<PJ>\", label_ids: [\"<L1>\"], due_date_at: \"<DUE>\" }) { id title code priority updated_at } }"}'
```

Only include changed fields.

## issues delete

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"mutation { deleteIssue(id: \"<ID>\") }"}'
```

Confirm with user before executing.

---

# Command: projects

Options:
- `list` — `--workspace <id>` (required) `--page <n>` `--limit <n>`
- `create` — `--title <t>` `--workspace <id>` (required), `--summary <t>` `--description <t>` `--priority <P>` `--icon <emoji>` `--status <id>` `--start <date>` `--end <date>` `--leader <id>` `--teams <id1,id2>` `--members <id1,id2>` `--labels <id1,id2>` (optional)
- `update` — `--id <id>` (required), same optional fields as create
- `delete` — `--id <id>` (required)

If missing required fields, ask user via AskUserQuestion.

## projects list

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"{ projects(getInput: { workspace_id: \"<WS_ID>\", page: <PAGE>, limit: <LIMIT> }) { items { id title code short_summary priority icon project_status_id leader_id start_at end_at created_by created_at is_deleted analytics { scope started completed } } totalCount hasMore } }"}'
```

Display: | Code | Title | Priority | Leader | Start | End | Progress (completed/scope) |

## projects create

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"mutation { createProject(createInput: { title: \"<TITLE>\", workspace_id: \"<WS_ID>\", short_summary: \"<SUMMARY>\", description: \"<DESC>\", priority: <PRIORITY>, icon: \"<ICON>\", project_status_id: \"<STATUS>\", start_at: \"<START>\", end_at: \"<END>\", leader_id: \"<LEADER>\", team_ids: \"<TEAMS>\", member_ids: \"<MEMBERS>\", label_ids: \"<LABELS>\" }) { id title code priority icon created_at } }"}'
```

Remove null optional fields.

## projects update

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"mutation { updateProject(updateInput: { id: \"<ID>\", title: \"<TITLE>\", short_summary: \"<SUMMARY>\", description: \"<DESC>\", priority: <PRIORITY>, icon: \"<ICON>\", project_status_id: \"<STATUS>\", start_at: \"<START>\", end_at: \"<END>\", leader_id: \"<LEADER>\", team_ids: \"<TEAMS>\", member_ids: \"<MEMBERS>\", label_ids: \"<LABELS>\" }) }"}'
```

Only include changed fields.

## projects delete

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"mutation { deleteProject(id: \"<ID>\") }"}'
```

Confirm with user before executing.

---

# Command: documents

Options:
- `list` — `--workspace <id>` (required) `--parent <document_id>` `--created-by <user_id>` `--page <n>` `--limit <n>`
- `get` — `--id <id>` (required)
- `create` — `--title <t>` `--workspace <id>` `--team <id>` (required), `--description <t>` `--parent <document_id>` (optional)
- `update` — `--id <id>` (required), `--title <t>` `--description <t>` (optional)
- `delete` — `--id <id>` (required)

If missing required fields, ask user via AskUserQuestion.

## documents list

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"{ documents(getInput: { workspace_id: \"<WS_ID>\", document_id: \"<PARENT>\", created_by: \"<USER>\", page: <PAGE>, limit: <LIMIT> }) { items { id title document_id team_id created_by created_at updated_at is_deleted } totalCount hasMore } }"}'
```

Remove null optional fields. Display: | Title | Team | Created By | Created |

## documents get

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"{ document(getInput: { id: \"<ID>\" }) { id title description document_id team_id workspace_id created_by created_at updated_at } }"}'
```

Render description as markdown if present.

## documents create

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"mutation { createDocument(createInput: { title: \"<TITLE>\", workspace_id: \"<WS_ID>\", team_id: \"<TEAM_ID>\", description: \"<DESC>\", document_id: \"<PARENT>\" }) { id title team_id created_at } }"}'
```

Remove null optional fields.

## documents update

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"mutation { updateDocument(updateInput: { id: \"<ID>\", title: \"<TITLE>\", description: \"<DESC>\" }) }"}'
```

Only include changed fields.

## documents delete

```
curl -s -X POST "<ENDPOINT>" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <API_KEY>" \
  -d '{"query":"mutation { removeDocument(id: \"<ID>\") }"}'
```

Confirm with user before executing.

---

# Enums Reference

**PriorityType**: `NO_PRIORITY` | `URGENT` | `HIGH` | `MEDIUM` | `LOW`

**ApiKeyScope**: `ISSUES_READ` | `ISSUES_WRITE` | `PROJECTS_READ` | `PROJECTS_WRITE` | `DOCUMENTS_READ` | `DOCUMENTS_WRITE` | `TEAMS_READ` | `MEMBERS_READ` | `APPOINTMENTS_READ` | `APPOINTMENTS_WRITE` | `AI_ANALYZE` | `AI_SUGGEST` | `AI_AUTO_ASSIGN` | `AI_REPORTS` | `AI_WEBHOOKS`

# Error Handling

- Auth error → API key invalid or expired
- Forbidden → scope not granted for this operation
- Not found → verify resource ID exists
- Validation → show which fields are invalid
- Always show the raw API error message
WSPACE_API_EOF

echo "[✓] Installed: wspace-api (CRUD issues/projects/documents)"

# wspace-setup.md
cat > "$COMMANDS_DIR/wspace-setup.md" << 'WSPACE_SETUP_EOF'
# WSpace Project Setup

One-command setup to integrate the current project with WSpace.

## Steps

### 1. Resolve API Key

- Check if `.env` file exists in current project root with `WSPACE_API_KEY`
- If exists, source it and use the key
- If not, check env var `WSPACE_API_KEY`
- If neither, ask user via AskUserQuestion for their WSpace API key

### 2. Detect Endpoint

- Try `https://api.wspaces.app/graphql` first
- Fallback to `http://localhost:8060/graphql`
- Test with a simple query to verify connectivity

### 3. Fetch Workspace Context

Query the API with:
```
{ appContext { workspace { id name url logo timezone large_company created_at updated_at } teams { id name identifier icon color } workflows { id name color type } labels { id name color } project_statuses { id name color type } members { id email full_name username } scopes } }
```

If error "requires API key authentication" (user-level key), query `workspaces` instead and ask user to pick one, then use a workspace-scoped key.

### 4. Create `.env` file

Write to `<project_root>/.env`:
```
export WSPACE_API_KEY="<key>"
```

Check `.gitignore` — if it exists, ensure `.env` is listed. If `.gitignore` doesn't exist, create one with `.env` entry.

### 5. Generate `CLAUDE.md`

Create/update `CLAUDE.md` in project root with all fetched data:

```markdown
# WSpace API Defaults

When running `/wspace-api` commands, use these defaults unless overridden:

## Connection
- **Endpoint:** `<ENDPOINT>`
- **API Key:** env `WSPACE_API_KEY`

## Workspace: <NAME>
- **Workspace ID:** `<ID>`
- **Workspace URL:** `<URL>`

## Teams
| Identifier | Name | ID |
|------------|------|----|
(list all teams)

## Workflows
| Name | ID | Type |
|------|----|------|
(list all workflows)

## Labels
| Name | ID |
|------|----|
(list all labels)

## Project Statuses
| Name | ID | Type |
|------|----|------|
(list all project statuses)

## Members
| Name | ID | Email |
|------|----|-------|
(list all members)

## Comments API
\`\`\`graphql
# Create comment
mutation(\$input: CreateCommentInput!) { createComment(createInput: \$input) }
# Query comments
{ comments(getInput: { issue_id: "<ISSUE_ID>", workspace_id: "<WS_ID>" }) { id content created_by user { full_name email } created_at } }
\`\`\`

## Auto-implement Workflow

**IMPORTANT: Chỉ xử lý issue được assign cho chính bot account.** Không tự nhận issue chưa assign. User phải chủ động assign issue cho bot trước.

### Phase 1: Pick up new issues
1. Fetch issues assigned to bot (assignee_id = bot ID) in **Backlog/Todo**
2. Move to **In Progress**
3. Analyze task -> comment kế hoạch triển khai lên issue
4. Chờ approval comment từ member (không phải bot)

### Phase 2: Respond to user comments on In Progress issues
1. Fetch issues assigned to bot in **In Progress**
2. Query comments cho mỗi issue
3. Tìm comment MỚI NHẤT từ non-bot member (created_by != bot ID)
4. **Đọc hiểu nội dung comment** để xác định intent, KHÔNG match keyword cứng:
   - **Approve/implement**: user đồng ý, yêu cầu triển khai -> implement code -> comment kết quả -> chuyển **In Review**
   - **Request more analysis**: user yêu cầu phân tích thêm -> phân tích -> comment kết quả (giữ In Progress)
   - **Feedback/revise**: user góp ý, sửa plan -> cập nhật plan -> comment plan mới (giữ In Progress)
   - **Reject/cancel**: user từ chối -> comment xác nhận -> move về **Backlog**
   - **Question**: user hỏi thêm -> trả lời bằng comment (giữ In Progress)
5. Nếu comment mới nhất là của bot -> bỏ qua (đang chờ user response)

### Flow
\`\`\`
User assign -> Backlog/Todo -> [Bot picks up] -> In Progress (comment plan)
  -> [User comments]
    -> approve      -> Bot implements -> In Review (comment results)
    -> analyze more -> Bot analyzes   -> In Progress (comment analysis)
    -> feedback     -> Bot revises    -> In Progress (comment new plan)
    -> reject       -> Bot confirms   -> Backlog
    -> question     -> Bot answers    -> In Progress (comment answer)
  -> [User reviews In Review & completes manually]
\`\`\`

## Schema Notes
- `UserEntity` uses `full_name` and `username` (not `first_name`/`last_name`)
- `IssueLabelEntity` uses `id` and `label_id` (not `name`/`color`)
```

### 6. Ask about Auto-loop

Ask user via AskUserQuestion:
- "Do you want to enable auto-implement loop?" with options:
  - "Yes - 5 min"
  - "Yes - 10 min"
  - "Yes - 30 min"
  - "No, I will run manually"

If yes, create a CronCreate with the selected interval using this prompt:

\`\`\`
Source <project_root>/.env for API key. Run two phases:

Phase 1 - New issues: Query issues assigned to bot in Backlog/Todo.
For each: move to In Progress, analyze task, comment plan on issue.

Phase 2 - Respond to comments: Query issues assigned to bot in In Progress.
For each: query comments, find latest non-bot comment.
Read and understand the comment intent (do NOT use keyword matching):
- Approve/implement -> implement code, comment results, move to In Review
- Request more analysis -> analyze further, comment findings (stay In Progress)
- Feedback/revise -> update plan, comment new plan (stay In Progress)
- Reject -> confirm cancellation, move to Backlog
- Question -> answer via comment (stay In Progress)
Skip if latest comment is from bot (waiting for user).

If nothing to process: "No new issues to process."
\`\`\`

### 7. Display Summary

Show the user:
- Workspace name and URL
- Number of teams, workflows, labels, members
- Scopes checklist (enabled/disabled)
- Files created: `.env`, `CLAUDE.md`, `.gitignore` (if modified)
- Auto-loop status (on/off, interval, job ID)
- Quick reference commands

## Input

$ARGUMENTS
WSPACE_SETUP_EOF

echo "[✓] Installed: wspace-setup (one-command project integration)"

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Commands available in Claude Code:"
echo "  /wspace-setup          Setup WSpace for current project"
echo "  /wspace-setup <key>    Setup with specific API key"
echo "  /wspace-api            Query WSpace API (issues, projects, docs)"
echo ""
echo "Quick start:"
echo "  1. cd into your project"
echo "  2. Open Claude Code: claude"
echo "  3. Run: /wspace-setup"
echo ""
