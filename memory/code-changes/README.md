---
tags: [code-changes, schema]
updated: 2026-04-13
---

# Code Changes — Schema Reference

Daily change logs live in this directory as `YYYY-MM-DD.md` files.
They are created automatically by the `/memorise` command.

---

## File Naming

```
YYYY-MM-DD.md
```

Each file covers one calendar day. If `/memorise` covers multiple days,
it creates or appends to each relevant day's file.

---

## Entry Schema

Each entry within a daily log follows this structure:

```markdown
## HH:MM — <commit-hash-7> <short description>

**Files changed:** `path/to/file.ts`, `path/to/other.ts`
**Commit:** `abc1234`
**Type:** feat | fix | refactor | chore | docs | test | style

### What changed
<1-3 sentences describing the change>

### Why
<Rationale from commit message or inferred from diff context>

### Learnings
<Any patterns, conventions, domain knowledge, or gotchas captured>

---
```

### Type Definitions

| Type | When to use |
|------|-------------|
| `feat` | New feature or capability added |
| `fix` | Bug or regression fixed |
| `refactor` | Code restructured without changing behaviour |
| `chore` | Build, config, dependency changes |
| `docs` | Documentation only |
| `test` | Test additions or changes |
| `style` | Formatting, naming, no logic change |

---

## Example Entry

```markdown
## 14:32 — a3f82bc Add user authentication middleware

**Files changed:** `src/middleware/auth.ts`, `src/routes/api.ts`
**Commit:** `a3f82bc`
**Type:** feat

### What changed
Added JWT validation middleware that sits in front of all `/api/*` routes.
Unauthenticated requests now receive a `401` with a `WWW-Authenticate` header.

### Why
The API was previously open — any client could call any endpoint.
This was the first step toward role-based access control (RBAC).

### Learnings
- This project uses `jose` (not `jsonwebtoken`) for JWT handling — different API
- Middleware is registered in `src/app.ts` via `app.use()`, not in individual route files
- The team tags security-related commits with `[security]` in the message

---
```
