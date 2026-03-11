# Auth

- Resolve `API_KEY`: check env `WSPACE_API_KEY`, or ask user via AskUserQuestion.
- Resolve `ENDPOINT`: `https://api.wspaces.app/graphql`.
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
