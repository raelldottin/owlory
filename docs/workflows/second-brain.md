# Second Brain Workflow

Every user prompt gets a concise local log entry under `SecondBrain/`.

## Required Shape

```text
SecondBrain/
  README.md
  INDEX.md
  sessions/
    YYYY-MM-DD/
      HHMMSS-short-slug.md
  templates/
    turn-entry.md
```

## Agent Steps

1. Create or update one session entry for the current task.
2. Record the user prompt or a concise non-sensitive summary when the prompt is very long.
3. Record interpretation, plan, files intentionally inspected/edited, commands, results, failures, and outcome.
4. Update `SecondBrain/INDEX.md`.
5. Redact secrets, tokens, credentials, private keys, and similarly sensitive values.

Keep entries factual. Do not include hidden reasoning.
