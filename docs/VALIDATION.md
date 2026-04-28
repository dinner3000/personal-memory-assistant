# Validation — Personal Memory Assistant

This document defines test scenarios and acceptance criteria for verifying the system works correctly.

## Test Methodology

Each scenario is run manually by interacting with the assistant from any platform (CLI, Telegram, Discord). Results are recorded with the date and outcome.

---

## Recording Tests

### T-REC-01: Basic Recording

**Scenario:** Tell the assistant something to remember from CLI.

**Steps:**
1. Start any Hermes session
2. Say: "Remember that I finished the quarterly review today and it went well"
3. Verify a journal entry was created at `journal/2026/MM-DD-*.md`
4. Verify the entry contains the date, tags, and details

**Expected:** Entry created with correct date. Content matches what was said.

**Result:**

---

### T-REC-02: Recording from Non-CLI Platform

**Scenario:** Tell the assistant something from Telegram (or Discord/Slack).

**Steps:**
1. Send a message to the Hermes bot on Telegram: "Remember I have a dentist appointment on May 5th"
2. Switch to CLI and ask: "What appointments do I have coming up?"
3. Verify the assistant recalls the dentist appointment

**Expected:** Entry captured and retrievable across platforms.

**Result:**

---

### T-REC-03: Journal-Worthy vs. Casual Distinction

**Scenario:** The assistant should distinguish between casual conversation and things worth recording.

**Steps:**
1. Say: "Good morning, how are you?"
2. Check that no journal entry was created
3. Say: "Remember I decided to adopt a cat named Milo"
4. Check that an entry was created

**Expected:** Casual greetings are not recorded. Explicit "remember" statements or clearly impactful statements are recorded.

**Result:**

---

## Retrieval Tests

### T-RET-01: Same-Session Retrieval

**Scenario:** Retrieve something recorded earlier in the same conversation.

**Steps:**
1. Say: "Remember that my favorite book is Dune"
2. Continue chatting about unrelated topics for several turns
3. Say: "What's my favorite book?"
4. Verify correct answer

**Expected:** Correct answer from memory (fast path) or journal.

**Result:**

---

### T-RET-02: Cross-Session Retrieval

**Scenario:** Retrieve something from a previous session.

**Steps:**
1. In session A: "Remember that I'm working on a mobile app called SnapLog"
2. End session A
3. Start a new session B (or `/reset`)
4. Say: "What project am I working on?"
5. Verify correct answer

**Expected:** Correct answer retrieved from memory or journal.

**Result:**

---

### T-RET-03: Cross-Platform Retrieval

**Scenario:** Record on CLI, retrieve on Telegram (or vice versa).

**Steps:**
1. On CLI: "Remember I met Sarah from Acme Corp at the conference"
2. Switch to Telegram: "Who did I meet at the conference?"
3. Verify correct answer

**Expected:** Correct answer across platforms (both share the same journal directory).

**Result:**

---

### T-RET-04: Time-Bound Retrieval

**Scenario:** Ask about events in a specific time period.

**Steps:**
1. Ensure at least 3 entries exist across different dates
2. Ask: "What happened in April 2026?"
3. Verify only entries from April 2026 are returned

**Expected:** Correct date-filtered results.

**Result:**

---

### T-RET-05: Tag-Based Retrieval

**Scenario:** Ask about entries with a specific tag.

**Steps:**
1. Ensure at least 2 entries exist with tag "health"
2. Ask: "What health-related things have I noted?"
3. Verify health-tagged entries are returned

**Expected:** Correct tag-filtered results.

**Result:**

---

## Durability Tests

### T-DUR-01: Survive Hermes Reinstall

**Scenario:** Journal entries survive Hermes Agent being reinstalled.

**Steps:**
1. Create several journal entries
2. (Simulate:) Move the journal directory, restore it
3. Ask questions about past entries

**Expected:** Entries are on filesystem independent of Hermes config. Survives reinstall as long as project directory is preserved.

**Result:**

---

### T-DUR-02: Git History Preservation

**Scenario:** Journal entries survive via git remote.

**Steps:**
1. Commit and push journal
2. Delete local project directory
3. Clone from GitHub
4. Ask about entries (pointing to the cloned journal)

**Expected:** All entries survive via git remote.

**Result:**

---

## Edge Cases

### T-EDG-01: Empty Journal

**Scenario:** User asks about past events before any entries exist.

**Steps:**
1. In a fresh setup with no entries
2. Ask: "What happened last week?"
3. Verify graceful response (no crash, no false positives)

**Expected:** Assistant responds that no entries were found, or that the journal is new.

**Result:**

---

### T-EDG-02: Very Long Entry

**Scenario:** User shares a long story or detailed note.

**Steps:**
1. Dictate a 1000+ word note about a complex topic
2. Verify it's saved as a complete entry
3. Ask about it later to verify full content is retrievable

**Expected:** Full content preserved, accessible later.

**Result:**

---

### T-EDG-03: Special Characters

**Scenario:** Entry contains special characters, emoji, or non-English text.

**Steps:**
1. Say: "Remember: 明天开会 with João — café at 3pm 🎉"
2. Verify entry contains the exact text
3. Search for "João" — should find the entry
4. Search for "café" — should find the entry

**Expected:** UTF-8 content preserved, grep finds it.

**Result:**

---

## Test Summary

| ID | Status | Date | Notes |
|---|---|---|---|
| T-REC-01 | ⬜ | — | Not yet run |
| T-REC-02 | ⬜ | — | Not yet run |
| T-REC-03 | ⬜ | — | Not yet run |
| T-RET-01 | ⬜ | — | Not yet run |
| T-RET-02 | ⬜ | — | Not yet run |
| T-RET-03 | ⬜ | — | Not yet run |
| T-RET-04 | ⬜ | — | Not yet run |
| T-RET-05 | ⬜ | — | Not yet run |
| T-DUR-01 | ⬜ | — | Not yet run |
| T-DUR-02 | ⬜ | — | Not yet run |
| T-EDG-01 | ⬜ | — | Not yet run |
| T-EDG-02 | ⬜ | — | Not yet run |
| T-EDG-03 | ⬜ | — | Not yet run |
