# Tools Reference

Daemon OS exposes 20 tools through the MCP protocol. This document provides
the complete reference for each tool, including parameters, return format,
and usage examples.

All tools return a JSON object with at minimum a `success` boolean. On failure,
an `error` string and optional `suggestion` string are included. On success,
a `data` object contains the tool-specific result. Some tools also return a
`context` object with the current app, window, focused element, and URL.

---

## Perception Tools

These tools read the screen state. They do not require app focus and do not
modify anything.

### daemon_context

Get orientation: focused app, window title, URL (for browsers), focused element,
and visible interactive elements. Always call this before acting on an app.

| Parameter | Type   | Required | Description                                  |
|-----------|--------|----------|----------------------------------------------|
| `app`     | string | No       | App name. If omitted, returns focused app.   |

**Returns**: App name, window title, URL (if browser), focused element details,
list of interactive elements with roles and names.

**Example**:
```json
{ "name": "daemon_context", "arguments": { "app": "Safari" } }
```

### daemon_state

List all running apps and their windows with titles, positions, and sizes.

| Parameter | Type   | Required | Description                      |
|-----------|--------|----------|----------------------------------|
| `app`     | string | No       | Filter to a specific app.        |

**Returns**: Array of app objects, each with name, PID, and window list.

**Example**:
```json
{ "name": "daemon_state", "arguments": {} }
```

### daemon_find

Find elements in any app by text, role, DOM id, CSS class, or identifier.

| Parameter    | Type    | Required | Description                                           |
|--------------|---------|----------|-------------------------------------------------------|
| `query`      | string  | No       | Text to search for (matches title, value, identifier).|
| `role`       | string  | No       | AX role filter (e.g., AXButton, AXTextField, AXLink). |
| `dom_id`     | string  | No       | Find by DOM id (web apps, bypasses depth limits).     |
| `dom_class`  | string  | No       | Find by CSS class.                                    |
| `identifier` | string  | No       | Find by AX identifier.                                |
| `app`        | string  | No       | Which app to search in.                               |
| `depth`      | integer | No       | Max search depth (default: 25, max: 100).             |

At least one search parameter is required.

**Returns**: Array of matching elements with role, name, position, and available actions.
Results are capped at 50 elements.

**Example**:
```json
{ "name": "daemon_find", "arguments": { "query": "Submit", "role": "AXButton", "app": "Chrome" } }
```

### daemon_read

Read text content from the screen using semantic depth tunneling.

| Parameter | Type    | Required | Description                               |
|-----------|---------|----------|-------------------------------------------|
| `app`     | string  | No       | Which app to read from.                   |
| `query`   | string  | No       | Narrow to a specific element first.       |
| `depth`   | integer | No       | How deep to read (default: 25).           |

**Returns**: Concatenated text content and item count.

**Example**:
```json
{ "name": "daemon_read", "arguments": { "app": "Chrome", "query": "main content" } }
```

### daemon_inspect

Full metadata about a single element. Call this before acting on something
when you need to verify its properties.

| Parameter | Type   | Required | Description            |
|-----------|--------|----------|------------------------|
| `query`   | string | Yes      | Element to inspect.    |
| `role`    | string | No       | AX role filter.        |
| `dom_id`  | string | No       | Find by DOM id.        |
| `app`     | string | No       | Which app.             |

**Returns**: Role, title, position, size, actionable status, supported actions,
editable flag, DOM id, description, value, and more.

**Example**:
```json
{ "name": "daemon_inspect", "arguments": { "query": "Send", "app": "Mail" } }
```

### daemon_element_at

Identify the element at a specific screen coordinate. Useful for bridging
screenshots to the accessibility tree.

| Parameter | Type   | Required | Description    |
|-----------|--------|----------|----------------|
| `x`       | number | Yes      | X coordinate.  |
| `y`       | number | Yes      | Y coordinate.  |

**Returns**: Full element metadata (same as daemon_inspect).

**Example**:
```json
{ "name": "daemon_element_at", "arguments": { "x": 500, "y": 300 } }
```

### daemon_screenshot

Take a screenshot of an app window. Returns a base64-encoded PNG as an MCP
image content block.

| Parameter         | Type    | Required | Description                                  |
|-------------------|---------|----------|----------------------------------------------|
| `app`             | string  | No       | App to screenshot. Defaults to frontmost.    |
| `full_resolution` | boolean | No       | Native resolution instead of 1280px resize.  |

**Returns**: MCP image content block with base64 PNG data, dimensions, and window title.
Requires Screen Recording permission.

**Example**:
```json
{ "name": "daemon_screenshot", "arguments": { "app": "Finder" } }
```

---

## Action Tools

These tools modify the UI. Click and type auto-manage focus. Press, hotkey,
and scroll require the `app` parameter to ensure correct targeting.

### daemon_click

Click an element using a dual-strategy approach: AX-native press first,
synthetic position-based fallback.

| Parameter | Type    | Required | Description                                       |
|-----------|---------|----------|---------------------------------------------------|
| `query`   | string  | No       | Element text/name to click.                       |
| `role`    | string  | No       | AX role filter.                                   |
| `dom_id`  | string  | No       | Click by DOM id.                                  |
| `app`     | string  | No       | Which app (auto-focuses if needed).               |
| `x`       | number  | No       | Click at X coordinate instead of element lookup.  |
| `y`       | number  | No       | Click at Y coordinate.                            |
| `button`  | string  | No       | left (default), right, or middle.                 |
| `count`   | integer | No       | Click count: 1=single, 2=double, 3=triple.        |

Either query/dom_id or x/y coordinates are required.

**Returns**: Method used (ax-native, synthetic, or coordinate) and element name.

**Example**:
```json
{ "name": "daemon_click", "arguments": { "query": "Compose", "app": "Gmail" } }
```

### daemon_type

Type text into a field. If `into` is specified, finds and focuses that field first.

| Parameter | Type    | Required | Description                                             |
|-----------|---------|----------|---------------------------------------------------------|
| `text`    | string  | Yes      | Text to type.                                           |
| `into`    | string  | No       | Target field name (finds via accessibility).            |
| `dom_id`  | string  | No       | Target field by DOM id.                                 |
| `app`     | string  | No       | Which app.                                              |
| `clear`   | boolean | No       | Clear the field before typing (default: false).         |

**Returns**: Readback verification of the typed text.

**Example**:
```json
{ "name": "daemon_type", "arguments": { "text": "Hello world", "into": "Subject", "app": "Mail" } }
```

### daemon_press

Press a single key with optional modifier keys.

| Parameter   | Type     | Required | Description                                              |
|-------------|----------|----------|----------------------------------------------------------|
| `key`       | string   | Yes      | Key name: return, tab, escape, space, delete, arrows, f1-f12. |
| `modifiers` | string[] | No       | Modifier keys: cmd, shift, option, control.              |
| `app`       | string   | No       | Auto-focus this app first (important for correct target).|

**Returns**: Success confirmation.

**Example**:
```json
{ "name": "daemon_press", "arguments": { "key": "return", "app": "Chrome" } }
```

### daemon_hotkey

Press a key combination. Modifier keys are automatically cleared afterward
to prevent stuck keys.

| Parameter | Type     | Required | Description                                           |
|-----------|----------|----------|-------------------------------------------------------|
| `keys`    | string[] | Yes      | Key combo, e.g., ["cmd", "s"] or ["cmd", "shift", "p"]. |
| `app`     | string   | No       | Auto-focus this app first.                            |

**Returns**: Success confirmation.

**Example**:
```json
{ "name": "daemon_hotkey", "arguments": { "keys": ["cmd", "l"], "app": "Chrome" } }
```

### daemon_scroll

Scroll content in a direction at the current position or at specific coordinates.

| Parameter   | Type    | Required | Description                           |
|-------------|---------|----------|---------------------------------------|
| `direction` | string  | Yes      | up, down, left, or right.             |
| `amount`    | integer | No       | Scroll amount in lines (default: 3).  |
| `app`       | string  | No       | Auto-focus this app first.            |
| `x`         | number  | No       | Scroll at specific X position.        |
| `y`         | number  | No       | Scroll at specific Y position.        |

**Returns**: Success confirmation with direction and amount.

**Example**:
```json
{ "name": "daemon_scroll", "arguments": { "direction": "down", "amount": 5, "app": "Chrome" } }
```

### daemon_focus

Bring an app or a specific window to the front.

| Parameter | Type   | Required | Description                                      |
|-----------|--------|----------|--------------------------------------------------|
| `app`     | string | Yes      | App name to focus.                               |
| `window`  | string | No       | Window title substring to focus a specific window.|

**Returns**: Confirmation with focused status.

**Example**:
```json
{ "name": "daemon_focus", "arguments": { "app": "Terminal", "window": "main" } }
```

### daemon_window

Manage windows: minimize, maximize, close, restore, move, resize, or list.

| Parameter | Type   | Required | Description                                               |
|-----------|--------|----------|-----------------------------------------------------------|
| `action`  | string | Yes      | minimize, maximize, close, restore, move, resize, or list.|
| `app`     | string | Yes      | Target app.                                               |
| `window`  | string | No       | Window title (if omitted, acts on frontmost window).      |
| `x`       | number | No       | X position for move.                                      |
| `y`       | number | No       | Y position for move.                                      |
| `width`   | number | No       | Width for resize.                                         |
| `height`  | number | No       | Height for resize.                                        |

**Returns**: Confirmation of the completed action.

**Example**:
```json
{ "name": "daemon_window", "arguments": { "action": "resize", "app": "Terminal", "width": 800, "height": 600 } }
```

---

## Wait Tool

### daemon_wait

Wait for a condition to be met by polling, instead of using fixed delays.

| Parameter   | Type   | Required | Description                                                   |
|-------------|--------|----------|---------------------------------------------------------------|
| `condition` | string | Yes      | One of: urlContains, titleContains, elementExists, elementGone, urlChanged, titleChanged. |
| `value`     | string | No       | Match value (required for urlContains, titleContains, elementExists, elementGone). |
| `timeout`   | number | No       | Max seconds to wait (default: 10).                            |
| `interval`  | number | No       | Poll interval in seconds (default: 0.5).                      |
| `app`       | string | No       | App to check against.                                         |

**Returns**: Whether the condition was met within the timeout.

**Example**:
```json
{ "name": "daemon_wait", "arguments": { "condition": "elementExists", "value": "Send", "app": "Chrome", "timeout": 15 } }
```

---

## Recipe Tools

### daemon_recipes

List all installed recipes with their descriptions and parameter definitions.
Always check this before performing multi-step tasks manually.

No parameters.

**Returns**: Array of recipe summaries (name, description, app, params) and count.

**Example**:
```json
{ "name": "daemon_recipes", "arguments": {} }
```

### daemon_run

Execute a recipe with parameter substitution. Returns step-by-step results.

| Parameter | Type   | Required | Description                          |
|-----------|--------|----------|--------------------------------------|
| `recipe`  | string | Yes      | Recipe name.                         |
| `params`  | object | No       | Parameter values for substitution.   |

**Returns**: Recipe name, steps completed, total steps, duration, and per-step results.

**Example**:
```json
{ "name": "daemon_run", "arguments": { "recipe": "slack-send", "params": { "channel": "general", "message": "Hello team" } } }
```

### daemon_recipe_show

View the full details of a recipe including all steps, parameters, and preconditions.

| Parameter | Type   | Required | Description  |
|-----------|--------|----------|--------------|
| `name`    | string | Yes      | Recipe name. |

**Returns**: Full recipe JSON including schema version, steps, params, and preconditions.

**Example**:
```json
{ "name": "daemon_recipe_show", "arguments": { "name": "slack-send" } }
```

### daemon_recipe_save

Install a new recipe from a JSON string. Validates the JSON before saving.

| Parameter     | Type   | Required | Description                   |
|---------------|--------|----------|-------------------------------|
| `recipe_json` | string | Yes      | Complete recipe JSON string.  |

**Returns**: Name of the saved recipe.

**Example**:
```json
{ "name": "daemon_recipe_save", "arguments": { "recipe_json": "{\"schema_version\":2,\"name\":\"my-recipe\",\"description\":\"...\",\"steps\":[...]}" } }
```

### daemon_recipe_delete

Delete a recipe by name.

| Parameter | Type   | Required | Description           |
|-----------|--------|----------|-----------------------|
| `name`    | string | Yes      | Recipe name to delete.|

**Returns**: Confirmation of deletion.

**Example**:
```json
{ "name": "daemon_recipe_delete", "arguments": { "name": "my-recipe" } }
```
