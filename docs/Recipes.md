# Recipes

Recipes are parameterized, replayable workflows stored as JSON files. They
automate multi-step tasks that would otherwise require sequential tool calls,
providing tested reliability and faster execution.

## Overview

Recipes are stored in `~/.daemon-os/recipes/` as individual JSON files.
Agents can list, run, inspect, save, and delete recipes through the five
recipe MCP tools.

The recipe system supports:
- Parameter substitution with `{{param}}` placeholders
- Precondition checking before execution
- Per-step wait conditions
- Configurable failure policies (stop or skip)
- Step-by-step result reporting with timing

## Schema v2 Format

Every recipe follows the schema v2 format:

```json
{
  "schema_version": 2,
  "name": "example-recipe",
  "description": "A brief description of what this recipe does",
  "app": "AppName",
  "params": {
    "message": {
      "type": "string",
      "description": "The message to send",
      "required": true
    },
    "channel": {
      "type": "string",
      "description": "Target channel name",
      "required": false
    }
  },
  "preconditions": {
    "app_running": "AppName",
    "url_contains": "example.com"
  },
  "steps": [
    {
      "id": 1,
      "action": "click",
      "target": {
        "computedNameContains": "New Message",
        "criteria": [
          { "attribute": "AXRole", "value": "AXButton" }
        ]
      },
      "note": "Open the compose dialog",
      "wait_after": {
        "condition": "elementExists",
        "value": "To",
        "timeout": 5
      }
    },
    {
      "id": 2,
      "action": "type",
      "params": {
        "text": "{{message}}",
        "into": "Message"
      },
      "note": "Type the message body"
    }
  ],
  "on_failure": "stop"
}
```

## Top-Level Fields

| Field            | Type   | Required | Description                                     |
|------------------|--------|----------|-------------------------------------------------|
| `schema_version` | int    | Yes      | Must be `2`.                                    |
| `name`           | string | Yes      | Unique recipe name (used as filename).          |
| `description`    | string | Yes      | Human-readable description.                     |
| `app`            | string | No       | Target app (auto-focused before execution).     |
| `params`         | object | No       | Parameter definitions (see below).              |
| `preconditions`  | object | No       | Conditions checked before running.              |
| `steps`          | array  | Yes      | Ordered list of steps to execute.               |
| `on_failure`     | string | No       | Global failure policy: `"stop"` (default) or `"skip"`. |

## Parameters

Parameters define placeholders that agents fill at runtime. Use `{{param_name}}`
syntax in step `params` values and `wait_after` values.

```json
"params": {
  "recipient": {
    "type": "string",
    "description": "Email address of the recipient",
    "required": true
  }
}
```

At runtime, the agent calls:
```json
{ "name": "daemon_run", "arguments": { "recipe": "send-email", "params": { "recipient": "user@example.com" } } }
```

All `{{recipient}}` occurrences in step params and wait_after values are
replaced with the provided value.

## Steps

Each step represents a single action. Steps run sequentially.

| Field        | Type   | Required | Description                                      |
|--------------|--------|----------|--------------------------------------------------|
| `id`         | int    | Yes      | Unique step identifier (for error reporting).    |
| `action`     | string | Yes      | Action to perform (see below).                   |
| `target`     | object | No       | AXorcist Locator for element targeting.          |
| `params`     | object | No       | Action-specific parameters.                      |
| `wait_after` | object | No       | Wait condition to verify after the action.       |
| `note`       | string | No       | Human-readable description of the step.          |
| `on_failure` | string | No       | Per-step failure policy (overrides global).       |

### Available Actions

| Action   | Description                  | Key Params                          |
|----------|------------------------------|-------------------------------------|
| `click`  | Click an element             | target or query/dom_id, button, count |
| `type`   | Type text into a field       | text (required), into, clear        |
| `press`  | Press a single key           | key (required), modifiers           |
| `hotkey` | Press a key combination      | keys (required, comma-separated)    |
| `focus`  | Focus an app or window       | app, window                         |
| `scroll` | Scroll in a direction        | direction, amount, x, y             |
| `wait`   | Inline wait (not wait_after) | condition, value, timeout           |

## Wait Conditions

Wait conditions can be used both as `wait_after` on steps and as standalone
`wait` action steps.

| Condition       | Requires Value | Description                              |
|-----------------|----------------|------------------------------------------|
| `urlContains`   | Yes            | Current URL contains the value.          |
| `titleContains` | Yes            | Window title contains the value.         |
| `elementExists` | Yes            | An element matching the value is found.  |
| `elementGone`   | Yes            | An element matching the value is gone.   |
| `urlChanged`    | No             | URL is different from when step started. |
| `titleChanged`  | No             | Title is different from when step started.|
| `delay`         | No             | Simple sleep (uses `timeout` as seconds).|

Example `wait_after`:
```json
"wait_after": {
  "condition": "elementExists",
  "value": "Compose",
  "timeout": 10
}
```

## Failure Policies

When a step fails, the failure policy determines what happens:

- **`"stop"`** (default): Stop execution immediately. Return a detailed error
  including the failed step, all completed step results, and current context
  for debugging.

- **`"skip"`**: Log the failure and continue to the next step. Useful for
  optional steps like dismissing a dialog that may or may not appear.

The `on_failure` field can be set globally at the recipe level or per-step.
Per-step policies override the global policy.

## Preconditions

Preconditions are checked before any steps execute. If a precondition fails,
the recipe returns an error with a diagnostic message and fix suggestion.

| Field          | Description                                 |
|----------------|---------------------------------------------|
| `app_running`  | Verify the named app is running.            |
| `url_contains` | Verify the current URL contains this string.|

## Writing Recipes

1. Use `daemon_context` and `daemon_find` to explore the target app's UI
2. Identify the sequence of actions needed
3. Note element names, roles, and DOM ids for reliable targeting
4. Add `wait_after` conditions for steps that trigger loading or navigation
5. Save with `daemon_recipe_save`
6. Test with `daemon_run` and iterate

Prefer DOM ids (`dom_id` in target criteria) over text queries for web apps,
as they are more stable across page changes and localization.
