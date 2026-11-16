---
name: codex-followup
description: Schedule an existing Codex chat to resume later or after an account rate limit resets, including when the local computer may be asleep or offline.
---

Use Codex's built-in scheduler through `mcp__codex_app__automation_update`. For a continuation in the same chat, create a heartbeat attached to that chat. A standalone Codex cron job starts a new chat and is appropriate only when the user wants an independent run. Keep Codex follow-ups in the app, without installing an OS cron job or LaunchAgent.

For a rate limit reset, read `get_usage_limits`. Use the reset time for the limiting window, convert its Unix timestamp to the user's timezone, and choose the first slot just after the reset. For another chat, use `list_threads` to resolve the intended chat precisely and pass its ID as `targetThreadId`. If the user asked to cover several chats sharing a checkout, stagger their first runs and tell each to preserve the other chats' edits.

For a local task that may miss its first slot, schedule later retries for long enough to cover the expected outage. Use a bounded window and tell the follow-up to delete itself through the app tool on the first successful trigger. The follow-up should inspect the chat's latest state and continue only work that is still unfinished and authorized. If the user says a chat has finished or cancels its follow-up, remove that chat's schedule using its returned ID.

Immediate automation creation rejects `DTSTART`. For a future start with repeated tries, choose local calendar slots using `BYMONTH`, `BYMONTHDAY`, `BYHOUR`, and `BYMINUTE` with an `UNTIL` bound. Ensure the earliest slot is after the reset. If the user needs explicit timezone anchoring, use the tool's suggested creation flow. Verify that the tool created the schedule and report the first slot and retry window in the user's timezone.

Local project work needs the desktop app running and the machine able to reach Codex. Later slots let the task retry when those conditions return. The schedule cannot wake the machine or give a cloud run access to the local checkout. See the [Codex scheduled tasks documentation](https://learn.chatgpt.com/docs/automations?surface=app).
