# Daemon OS - MCP Agent Instructions

You have Daemon OS, a tool that lets you see and operate any macOS application
through the accessibility tree. No screenshots needed for navigation. Every button,
text field, link, and label is available as structured data.

## Rule 1: Always Check Recipes First

Before doing ANY multi-step task manually, call `daemon_recipes`.

If a recipe exists for what you need, use `daemon_run` with the recipe name
and parameters. Recipes are tested, reliable, and faster than manual steps.

## Rule 2: Orient Before Acting

Before interacting with any app, call `daemon_context` with the app name.

This tells you: which app/window is active, the current URL (for browsers),
what element is focused, and what interactive elements are visible.

**If you skip this, you will click the wrong thing.**

## Rule 3: How to Find Elements

Use `daemon_find` with the most specific identifier available:
- `dom_id` for web apps (most reliable, bypasses depth limits)
- `identifier` for native apps with developer IDs
- `query` + `role` for general searches (e.g., query:"Compose", role:"AXButton")
- `query` alone as a fallback

Use `daemon_inspect` to examine an element before acting on it.
Use `daemon_element_at` to identify elements from screenshots.

## Rule 4: How Focus Works

**Perception tools work from background** (no focus needed):
- daemon_context, daemon_state, daemon_find, daemon_read, daemon_inspect,
  daemon_element_at, daemon_screenshot

**Click and type try AX-native first** (no focus), then synthetic fallback (auto-focuses):
- daemon_click, daemon_type

**Press, hotkey, scroll need focus** - always pass the `app` parameter:
- daemon_press, daemon_hotkey, daemon_scroll

Focus is automatically saved and restored after action tools.

## Rule 5: Key Patterns

### Navigate Chrome to a URL
```
daemon_hotkey keys:["cmd","l"] app:"Chrome"  → address bar focused
daemon_type text:"https://example.com"       → URL entered
daemon_press key:"return" app:"Chrome"       → navigate
daemon_wait condition:"urlContains" value:"example.com" app:"Chrome"
```

### Fill a form
```
daemon_click query:"Compose" app:"Chrome"    → click button
daemon_type text:"hello@example.com" into:"To" app:"Chrome"
daemon_press key:"tab" app:"Chrome"          → move to next field
daemon_type text:"Subject line" into:"Subject" app:"Chrome"
```

### Wait instead of guessing
```
daemon_wait condition:"elementExists" value:"Send" app:"Chrome"
daemon_wait condition:"urlContains" value:"inbox" timeout:15 app:"Chrome"
daemon_wait condition:"elementGone" value:"Loading" app:"Chrome"
```

## Rule 6: Handle Failures

If an action fails:
1. Call `daemon_context` to see current state
2. Call `daemon_screenshot` for visual confirmation
3. Try a different approach (different query, coordinates, etc.)

Don't retry the same thing 5 times. If daemon_click fails, it already tried
both AX-native and synthetic. The element might not exist, might be hidden,
or might be blocked by a modal.

## Tool Reference

| Tool | Purpose | Needs Focus? |
|------|---------|-------------|
| daemon_context | Where am I? URL, focused element, actions | No |
| daemon_state | All running apps and windows | No |
| daemon_find | Find elements by text, role, DOM id | No |
| daemon_read | Read text content from screen | No |
| daemon_inspect | Full element metadata | No |
| daemon_element_at | What's at these coordinates? | No |
| daemon_screenshot | Visual capture for debugging | No |
| daemon_click | Click element or coordinates | Auto |
| daemon_type | Type text, optionally into a field | Auto |
| daemon_press | Press single key | Yes - use `app` |
| daemon_hotkey | Key combo (cmd+s, etc.) | Yes - use `app` |
| daemon_scroll | Scroll content | Yes - use `app` |
| daemon_focus | Bring app to front | N/A |
| daemon_window | Window management | No |
| daemon_wait | Wait for condition | No |
| daemon_recipes | List recipes | No |
| daemon_run | Execute recipe | Auto |
| daemon_recipe_show | View recipe details | No |
| daemon_recipe_save | Save new recipe | No |
| daemon_recipe_delete | Delete recipe | No |
