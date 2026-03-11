# WSpaces Claude Integration

Tich hop [WSpace](https://wspaces.app) voi [Claude Code](https://claude.ai/claude-code) — tu dong quan ly issues, projects, documents thong qua GraphQL API.

## Cai dat

### Yeu cau
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- WSpace API Key (lay tu WSpace Settings > Apps hoac Settings > API Keys)

### Cai dat 1 lenh

```bash
git clone git@github.com:trandactruong/wspaces-claude.git
bash wspaces-claude/wspace-install.sh
```

Sau khi chay xong, ban se co 2 slash commands trong Claude Code:
- `/wspace-setup` — Setup WSpace cho project hien tai
- `/wspace-api` — Tuong tac voi WSpace API

## Su dung

### 1. Setup project

Mo Claude Code trong project cua ban:

```bash
cd my-project
claude
```

Chay setup:

```
/wspace-setup
```

Setup se:
- Hoi API key (hoac dung key co san)
- Ket noi va lay thong tin workspace (teams, workflows, labels, members)
- Tao file `.env` (chua API key)
- Tao file `CLAUDE.md` (config mac dinh cho project)
- Cap nhat `.gitignore`
- Hoi bat auto-loop (5m / 10m / 30m / thu cong)

### 2. Cac lenh WSpace API

```
/wspace-api context                          # Xem workspace info + scopes
/wspace-api workspaces                       # Liet ke workspaces
/wspace-api issues list                      # Liet ke issues
/wspace-api issues get --team IVT --code 3   # Xem chi tiet issue
/wspace-api issues create --title "Bug fix"  # Tao issue moi
/wspace-api issues update --id <id> --priority HIGH
/wspace-api projects list                    # Liet ke projects
/wspace-api documents list                   # Liet ke documents
```

Khi da setup, khong can truyen `--workspace` hay `--team` — tu dong dung defaults tu `CLAUDE.md`.

### 3. Auto-implement workflow

Bat auto-loop de bot tu dong xu ly issues:

```
/loop 5m /wspace-api issues list
```

Hoac chon khi chay `/wspace-setup`.

#### Flow

```
User assign issue cho Bot
  -> Backlog/Todo
  -> [Bot picks up] -> In Progress (comment ke hoach)
  -> [User comment phan hoi]
    -> dong y       -> Bot implement -> In Review (comment ket qua)
    -> phan tich them -> Bot phan tich -> In Progress (comment ket qua)
    -> gop y/sua    -> Bot cap nhat   -> In Progress (comment plan moi)
    -> tu choi      -> Bot xac nhan   -> Backlog
    -> hoi them     -> Bot tra loi    -> In Progress
  -> [User review In Review & complete thu cong]
```

#### Cach hoat dong

1. **User tao issue** tren WSpace va **assign cho bot** (Claude Leader)
2. **Bot tu dong pick up** — chuyen sang In Progress, phan tich task, comment ke hoach trien khai
3. **User review plan** — comment tren issue de phan hoi:
   - "ok trienk khai di" -> bot implement code
   - "phan tich them phan X" -> bot phan tich tiep
   - "sua lai plan" -> bot cap nhat
4. **Bot implement xong** -> comment ket qua + chuyen sang In Review
5. **User review** va complete thu cong

> Bot chi xu ly issues duoc assign cho no. Khong tu nhan issues.

## Cau truc files

Sau khi setup, project se co:

```
my-project/
  .env              # WSPACE_API_KEY
  .gitignore        # .env duoc ignore
  CLAUDE.md         # WSpace config defaults
```

Claude Code commands (global):

```
~/.claude/commands/
  wspace-api.md     # /wspace-api command
  wspace-setup.md   # /wspace-setup command
```

## Chuyen sang may khac

```bash
# Tren may moi
npm install -g @anthropic-ai/claude-code
git clone git@github.com:trandactruong/wspaces-claude.git
bash wspaces-claude/wspace-install.sh

# Sau do trong project
claude
/wspace-setup
```

## API Reference

### Endpoints
- Production: `https://api.wspaces.app/graphql`
- Local: `http://localhost:8060/graphql`

### Authentication
Header: `x-api-key: <API_KEY>`

### Scopes
| Scope | Mo ta |
|-------|-------|
| ISSUES_READ / WRITE | Doc/ghi issues |
| PROJECTS_READ / WRITE | Doc/ghi projects |
| DOCUMENTS_READ / WRITE | Doc/ghi documents |
| TEAMS_READ | Doc teams |
| MEMBERS_READ | Doc members |
| APPOINTMENTS_READ / WRITE | Doc/ghi appointments |

### Priority
`NO_PRIORITY` | `URGENT` | `HIGH` | `MEDIUM` | `LOW`
