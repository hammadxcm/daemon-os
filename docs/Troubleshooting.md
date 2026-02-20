# Troubleshooting

This guide covers common issues, how to interpret `daemon doctor` output,
and solutions for permission-related problems.

## Quick Diagnosis

Run the built-in diagnostic tool:

```bash
daemon doctor
```

Doctor performs these checks in order:
1. Binary location and version
2. Accessibility permission
3. Screen Recording permission
4. Running daemon processes (detects stale instances)
5. MCP client configuration
6. Installed recipes
7. Accessibility tree readability

If all checks pass, Doctor reports "All checks passed. Daemon OS is healthy."

## Common Errors

### "Accessibility: NOT GRANTED"

**Symptom**: All tools except `daemon_screenshot` fail. Doctor reports
Accessibility as not granted.

**Fix**:
1. Open **System Settings > Privacy & Security > Accessibility**
2. Add the application that runs Daemon OS (your terminal or MCP client)
3. Toggle the permission on
4. If the app was already listed, toggle it off and back on
5. Run `daemon doctor` again to verify

Note: If your MCP client launches `daemon` as a subprocess, the MCP client
application needs the permission, not Terminal.

### "Screen Recording: not granted"

**Symptom**: `daemon_screenshot` fails with "Screenshot capture failed".
All other tools work normally.

**Fix**:
1. Open **System Settings > Privacy & Security > Screen Recording**
2. Add your terminal application or MCP client
3. Toggle the permission on

This is a warning, not a critical error. Daemon OS works fully without
screenshots -- agents can navigate using the accessibility tree alone.

### "Application not found"

**Symptom**: Tool returns `"error": "Application 'AppName' not found"`.

**Causes and fixes**:
- The app is not running. Launch it first.
- The app name does not match. Use `daemon_state` to see exact app names.
- App name matching is case-insensitive and uses "contains" logic. For example,
  "chrome" matches "Google Chrome".

### "Element not found"

**Symptom**: `daemon_click`, `daemon_find`, or `daemon_inspect` cannot locate
an element.

**Causes and fixes**:
- The element is not visible (off-screen, behind a modal, in a collapsed section).
  Use `daemon_context` to see what is currently visible.
- The element text has changed. Use `daemon_read` to see current text content.
- The search depth is insufficient. Increase the `depth` parameter (up to 100).
- For web apps, prefer `dom_id` over text queries for more reliable targeting.

### "No element found at (x, y)"

**Symptom**: `daemon_element_at` returns no element.

**Fix**: The coordinates may be outside any window. Use `daemon_state` to check
window positions and sizes.

### "Click failed" / "Action failed"

**Symptom**: `daemon_click` fails after trying both AX-native and synthetic strategies.

**Causes and fixes**:
- Element is not actionable (disabled, hidden, or off-screen). Use `daemon_inspect`
  to check the element's actionable status.
- A modal dialog is blocking the click. Use `daemon_context` to detect modals.
- Try clicking by coordinates (x, y) instead of element query.

### "Timed out waiting for condition"

**Symptom**: `daemon_wait` times out without the condition being met.

**Fixes**:
- Increase the `timeout` parameter.
- Verify the condition can actually be met by checking with `daemon_context`.
- For `elementExists`, verify the exact element name with `daemon_find`.
- For `urlContains`, verify the URL pattern with `daemon_context`.

### Multiple daemon processes detected

**Symptom**: Doctor reports more than one `daemon mcp` process running.

**Fix**: Kill stale processes. Doctor provides the specific kill commands:
```bash
kill <PID>
```

This typically happens when an MCP client disconnects without the server
process terminating cleanly.

### "MCP Config: daemon-os not configured"

**Symptom**: Doctor cannot find Daemon OS in any MCP client configuration.

**Fix**: Run `daemon setup` for interactive configuration, or manually add
the server configuration to your MCP client:

```json
{
  "mcpServers": {
    "daemon-os": {
      "type": "stdio",
      "command": "/usr/local/bin/daemon",
      "args": ["mcp"]
    }
  }
}
```

### Recipes directory missing

**Symptom**: Doctor reports `~/.daemon-os/recipes/` does not exist.

**Fix**: Run `daemon setup` to create the directory and install bundled recipes.
Or create it manually:
```bash
mkdir -p ~/.daemon-os/recipes
```

### Broken recipes

**Symptom**: Doctor reports recipes that failed to decode.

**Fix**: Doctor lists the specific broken recipe files and their decode errors.
Common issues include missing required fields (`schema_version`, `name`,
`description`, `steps`) or invalid JSON syntax. Fix the JSON or delete the
broken recipe file from `~/.daemon-os/recipes/`.
