# Daemon OS

A vendor-neutral macOS MCP server that gives AI agents eyes and hands on the desktop.
Daemon OS exposes the macOS accessibility tree and screen capture through 20 MCP tools,
enabling any AI agent to perceive, navigate, and operate native and web applications.

## Features

- **20 MCP tools** covering perception, actions, waiting, and recipes
- **Accessibility tree access** -- read any on-screen element without screenshots
- **Semantic depth tunneling** -- intelligently traverses deep UI hierarchies
- **Dual-strategy click** -- AX-native press first, synthetic position fallback
- **Recipe engine** -- parameterized, replayable multi-step workflows (schema v2)
- **Multi-client support** -- works with any MCP-compatible AI client
- **Auto-detected transport** -- Content-Length framing or NDJSON, no configuration needed
- **Focus management** -- automatic save/restore across action tools
- **Vendor-neutral** -- no lock-in to any specific AI provider

## Quick Install

### Homebrew (recommended)

```bash
brew install daemon-os
```

### From Source

```bash
git clone https://github.com/daemon-os/daemon-os.git
cd daemon-os
swift build -c release
cp .build/release/daemon /usr/local/bin/daemon
```

Requires macOS 14+ and Swift 6.2.

## Quick Start

### 1. Run the setup wizard

```bash
daemon setup
```

This guides you through granting Accessibility and Screen Recording permissions
and configuring your MCP client.

### 2. Verify the installation

```bash
daemon doctor
```

Doctor checks permissions, running processes, MCP client configuration,
installed recipes, and accessibility tree readability.

### 3. Check status

```bash
daemon status
```

Prints a one-line summary of permission grants, recipe count, and readiness.

## CLI Commands

| Command          | Description                                 |
|------------------|---------------------------------------------|
| `daemon mcp`    | Start the MCP server (used by MCP clients)  |
| `daemon setup`  | Interactive first-time setup wizard         |
| `daemon doctor` | Diagnose issues and suggest fixes           |
| `daemon status` | Quick health check                          |
| `daemon version`| Print version                               |

## Tools

Daemon OS exposes 20 tools through the MCP protocol, grouped into four categories.

### Perception (7 tools)

| Tool                | Description                                              |
|---------------------|----------------------------------------------------------|
| `daemon_context`    | Get focused app, window title, URL, and interactive elements |
| `daemon_state`      | List all running apps and their windows                  |
| `daemon_find`       | Find elements by text, role, DOM id, class, or identifier|
| `daemon_read`       | Read text content from screen via semantic depth tunneling|
| `daemon_inspect`    | Full metadata for a single element                       |
| `daemon_element_at` | Identify the element at given screen coordinates         |
| `daemon_screenshot` | Capture a screenshot as base64 PNG                       |

### Actions (7 tools)

| Tool                | Description                                              |
|---------------------|----------------------------------------------------------|
| `daemon_click`      | Click an element (AX-native first, synthetic fallback)   |
| `daemon_type`       | Type text into a field, optionally targeting by name     |
| `daemon_press`      | Press a single key with optional modifiers               |
| `daemon_hotkey`     | Press a key combination (e.g., Cmd+Shift+P)              |
| `daemon_scroll`     | Scroll content in any direction                          |
| `daemon_focus`      | Bring an app or specific window to the front             |
| `daemon_window`     | Window management: move, resize, minimize, maximize, close|

### Wait (1 tool)

| Tool                | Description                                              |
|---------------------|----------------------------------------------------------|
| `daemon_wait`       | Poll for a condition (URL, title, element) with timeout  |

### Recipes (5 tools)

| Tool                  | Description                                            |
|-----------------------|--------------------------------------------------------|
| `daemon_recipes`      | List all installed recipes with descriptions           |
| `daemon_run`          | Execute a recipe with parameter substitution           |
| `daemon_recipe_show`  | View full recipe details, steps, and parameters        |
| `daemon_recipe_save`  | Install a new recipe from JSON                         |
| `daemon_recipe_delete`| Delete a recipe                                        |

## Architecture

```
MCP Client (stdin/stdout)
    |
    v
MCPServer -- auto-detects Content-Length or NDJSON transport
    |
    v
MCPDispatch -- routes tool calls to modules
    |
    +---> Perception (7 tools) ---> AXorcist (accessibility tree)
    +---> Actions (7 tools) ------> AXorcist + InputDriver + FocusManager
    +---> WaitManager (1 tool) ---> polling loop with AXorcist queries
    +---> RecipeEngine (5 tools) -> RecipeStore + step-by-step execution
```

See [docs/Architecture.md](docs/Architecture.md) for the full design overview.

## Documentation

- [Architecture](docs/Architecture.md) -- module design, data flow, and key decisions
- [Setup](docs/Setup.md) -- prerequisites, installation, and permissions
- [Tools](docs/Tools.md) -- complete reference for all 20 tools
- [Recipes](docs/Recipes.md) -- writing and managing replayable workflows
- [Contributing](docs/Contributing.md) -- development setup, testing, and PR process
- [Troubleshooting](docs/Troubleshooting.md) -- common errors and fixes

## MCP Client Configuration

Add to your MCP client configuration:

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

The server ships agent instructions in the MCP `initialize` response,
so connected agents automatically learn how to use the tools effectively.

## License

MIT
