---
name: journal-setup
description: "Initialize journal backup by setting up a remote git repository. Guides the user through creating a GitHub repo and connecting it for automatic sync."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [journal, memory, personal-memory-assistant, setup, backup, git]
    related_skills: [journal-record, project-continue]
---

# Journal Setup — Backup & Sync

## Overview

Helps the user set up a remote git repository for their journal entries. Without a remote, journal entries are only stored locally — a remote provides backup and cross-device sync.

This skill is triggered automatically when:
- The user saves their first journal entry and no remote is configured
- The user asks to "set up backup", "add remote", "configure sync", etc.

## Detection

Check if the journal has a remote configured:

```bash
cd ~/.hermes/journal && git remote -v
```

Or use $HERMES_HOME if set:
```bash
cd $HERMES_HOME/journal && git remote -v
```

- **Output contains `origin`** → remote is configured (skip setup)
- **Output empty** → no remote (need setup)

## Scene 1: First Entry — No Remote Warning

When the user saves their first journal entry and no remote is configured, inform them naturally:

> "Your journal entry is saved locally at ~/.hermes/journal/. It's not backed up to any remote yet. If you'd like to set up GitHub backup for automatic daily sync, just say 'set up journal backup' and I'll guide you through it."

Do NOT be pushy — one mention is enough. The user can choose to do it later or never.

Do NOT save this warning as a journal entry.

## Scene 2: Setup Process (triggered by user)

When the user asks to set up backup, follow these steps:

### Step 1: Check Current State

```bash
cd ~/.hermes/journal && git remote -v
```

If a remote already exists, tell the user and offer to test it instead.

### Step 2: Present Instructions

Tell the user to create a new private (or public) repository on GitHub:

> "To set up backup for your journal:
>
> 1. Go to https://github.com/new
> 2. Create a new repository (e.g., 'pma-journal')
> 3. **Do NOT** initialize it with README, .gitignore, or license
> 4. Copy the repo URL (HTTPS or SSH)
>
> When you have the URL, paste it here and I'll connect it."

### Step 3: Collect the URL

The user provides the repo URL. Validate it looks like a git URL:
- `https://github.com/username/repo.git`
- `git@github.com:username/repo.git`

### Step 4: Configure Remote

```bash
cd ~/.hermes/journal && git remote add origin <URL>
```

If HTTPS, also set up credential helper for non-interactive push (the daily cron needs this):

```bash
git remote set-url origin https://<TOKEN>@github.com/username/repo.git
git config credential.helper '!f() { echo "username=token"; echo "password=$(gh auth token)"; }; f'
```

Or if SSH, just:
```bash
git remote add origin git@github.com:username/repo.git
```

### Step 5: Push and Verify

```bash
cd ~/.hermes/journal && git push -u origin main
```

Verify it worked:
```bash
git remote -v && echo "Remote configured: OK"
```

### Step 6: Confirm

> "Journal backup is set up! Your entries will be synced to GitHub daily at 11 PM. You can also use this repo to access your journal from other devices by cloning it."

## Scene 3: Test Existing Remote

If the user asks to test their backup:

```bash
cd ~/.hermes/journal && git push
```

Report back: "Push successful. Your journal is backed up to GitHub."

If the push fails, diagnose:
- Auth error → suggest re-authenticating: `gh auth login`
- Network error → suggest checking connection

## Verification

- [ ] Check if remote exists: `git remote -v`
- [ ] If no remote: informed user of options
- [ ] If setup requested: guided user through GitHub repo creation
- [ ] Remote added and push verified
- [ ] Credential helper configured for cron sync
