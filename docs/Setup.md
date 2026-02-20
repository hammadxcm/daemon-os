# Setup

This guide covers installing Daemon OS, granting the required macOS permissions,
and configuring MCP clients to connect.

## Prerequisites

- **macOS 14 (Sonoma) or later** -- required for ScreenCaptureKit APIs
- **Swift 6.2** -- required for building from source (ships with Xcode 16+)
- **MCP-compatible AI client** -- any client that speaks the Model Context Protocol

## Installation

### Homebrew (recommended)

```bash
brew install daemon-os
```

### From Source

```bash
git clone https://github.com/daemon-os/daemon-os.git
cd daemon-os
swift build -c release
```

Copy the binary to your PATH:

```bash
cp .build/release/daemon /usr/local/bin/daemon
```

Or use the Makefile shortcut:

```bash
make install
```

### Verify Installation

```bash
daemon version
```

Should print `Daemon OS v3.0.0` (or the current version).

## Permissions

Daemon OS requires two macOS permissions to function.

### Accessibility (required)

Accessibility access is mandatory. Without it, Daemon OS cannot read or
interact with any application UI.

1. Open **System Settings > Privacy & Security > Accessibility**
2. Click the lock to make changes
3. Add your terminal application (Terminal, iTerm2, VS Code, Cursor, etc.)
4. Toggle the permission on

If you run Daemon OS via an MCP client that launches it as a subprocess,
the MCP client application itself needs Accessibility permission.

### Screen Recording (optional, recommended)

Screen Recording permission is needed for `daemon_screenshot`. Without it,
all other tools work normally but screenshots will fail.

1. Open **System Settings > Privacy & Security > Screen Recording**
2. Add your terminal application or MCP client
3. Toggle the permission on

### Verify Permissions

```bash
daemon doctor
```

Doctor checks both permissions and reports their status. If either is missing,
it tells you exactly which app to add and where.

## MCP Client Configuration

Daemon OS is a stdio-based MCP server. Configure it in your MCP client by
pointing to the `daemon` binary with the `mcp` argument.

### Generic Configuration

Add this to your MCP client's server configuration:

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

If you installed via Homebrew, the binary path is typically
`/opt/homebrew/bin/daemon` (Apple Silicon) or `/usr/local/bin/daemon` (Intel).

### Configuration File Locations

Daemon OS's `daemon doctor` command checks these known locations:

| Client  | Config Path              |
|---------|--------------------------|
| Generic | `~/.daemon-os/mcp-config.json` |

### Using the Setup Wizard

The interactive setup wizard handles configuration automatically:

```bash
daemon setup
```

It will:
1. Check and prompt for Accessibility permission
2. Check and prompt for Screen Recording permission
3. Detect installed MCP clients
4. Write the MCP server configuration

### Multi-Client Support

Daemon OS supports multiple simultaneous MCP client connections. Each client
launches its own `daemon mcp` process. There is no shared state between
processes -- each server instance is independent.

To verify that no stale processes are running:

```bash
daemon doctor
```

Doctor reports if multiple daemon MCP processes are detected and provides
kill commands for stale ones.
