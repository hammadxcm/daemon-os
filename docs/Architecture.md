# Architecture

This document describes the internal design of Daemon OS, its module structure,
data flow, and key design decisions.

## Module Overview

```
Sources/
  DaemonOS/
    Server/
      MCPServer.swift           JSON-RPC server over stdio
      MCPDispatch.swift         Routes tool calls to module functions
      MCPTools.swift            Tool definitions (names, schemas, descriptions)
      Transport/
        ContentLengthTransport  Content-Length: N\r\n\r\n framing
        NDJSONTransport         Newline-delimited JSON framing
        TransportProtocol       Transport abstraction
    Perception/
      Perception.swift          Facade for all 7 perception tools
      ContextProvider.swift     daemon_context: app, window, URL, elements
      StateProvider.swift       daemon_state: running apps and windows
      ElementSearcher.swift     daemon_find: semantic depth search
      ContentReader.swift       daemon_read: text extraction via depth tunneling
      Inspector.swift           daemon_inspect: full element metadata
      ScreenshotCapture.swift   daemon_screenshot: ScreenCaptureKit bridge
    Actions/
      Actions.swift             Facade for all 7 action tools
      ClickHandler.swift        daemon_click: dual-strategy click
      TypeHandler.swift         daemon_type: text input with field targeting
      KeyHandler.swift          daemon_press / daemon_hotkey: key events
      ScrollHandler.swift       daemon_scroll: directional scrolling
      FocusManager.swift        daemon_focus + focus save/restore
      WindowController.swift    daemon_window: move, resize, minimize, etc.
      ActionHelpers.swift       Shared utilities for action tools
      BatchExecutor.swift       Batch action execution support
    Wait/
      WaitManager.swift         daemon_wait: polling-based condition waits
      WaitConditionType.swift   Enum of valid wait conditions
    Recipes/
      RecipeEngine.swift        Step-by-step recipe execution
      RecipeStore.swift         File-based recipe storage (~/.daemon-os/recipes/)
      RecipeTypes.swift         Schema v2 data structures
      RecipeAction.swift        Action dispatch within recipes
      ParameterSubstitutor.swift  {{param}} replacement
      FailurePolicy.swift       Stop vs. skip on step failure
    Screenshot/
      ScreenCapture.swift       ScreenCaptureKit wrapper and permission check
    Common/
      Types.swift               ToolResult, ContextInfo, DaemonError, constants
      AppResolver.swift         Find running apps by name
      ElementFinder.swift       DOM id lookup, web area detection, URL reading
      ElementCache.swift        TTL-based element cache (2s default)
      ObserverManager.swift     AX notification subscriptions
      LocatorBuilder.swift      Build AXorcist Locator from query/role/domId
      ParamExtractor.swift      Safe parameter extraction from dictionaries
      PathHintNavigator.swift   Navigate AX tree via path hints
      ErrorBuilder.swift        Structured error response construction
      Logger.swift              Logging to stderr
      Protocols.swift           Testability protocols for dependency injection
      Constants.swift           Shared constants
  daemon/
    main.swift                  CLI entry point (mcp, setup, doctor, status)
    Doctor.swift                Diagnostic tool
    SetupWizard.swift           First-time setup wizard
```

## Data Flow

### Tool Call Lifecycle

```
1. MCP Client sends JSON-RPC request via stdin
       |
2. MCPServer.readMessage()
   - Auto-detects transport on first byte: 'C' -> Content-Length, '{' -> NDJSON
   - Parses JSON-RPC envelope (method, id, params)
       |
3. MCPServer dispatches by method:
   - "initialize"  -> server info + agent instructions
   - "tools/list"  -> MCPTools.definitions() (all 20 tool schemas)
   - "tools/call"  -> MCPDispatch.handle(params)
       |
4. MCPDispatch.handle()
   - Extracts tool name and arguments
   - Routes to the appropriate module function
   - Wraps ToolResult as MCP content array
       |
5. Module executes:
   - Perception: queries AXorcist for element data
   - Actions: finds element, executes via AX-native or synthetic input
   - Wait: polls condition in a loop until met or timeout
   - Recipes: validates params, checks preconditions, runs steps sequentially
       |
6. MCPServer.writeResponse()
   - Serializes JSON-RPC response
   - Writes using the detected transport format
```

### Screenshot Flow (Special Case)

Screenshot results use MCP image content type rather than text-wrapped JSON:

```
daemon_screenshot -> ScreenshotCapture.captureScreenshotSync()
    -> ScreenCaptureKit (async, bridged to sync via RunLoop)
    -> base64 PNG returned as MCP image content block
```

## Key Design Decisions

### Semantic Depth Tunneling

The macOS accessibility tree can be extremely deep (100+ levels in web apps).
Daemon OS uses a "semantic depth budget" (default: 25) that counts only
semantically meaningful nodes (buttons, links, text fields) rather than
structural containers (groups, scroll areas). This lets tools reach deep
into web app DOMs without exponential traversal cost.

The budget is configurable per-call via the `depth` parameter, with a hard
maximum of 100 levels.

### Dual-Strategy Click

`daemon_click` uses a two-phase approach:

1. **AX-native press**: Sends AXPress action via AXorcist. This works without
   focusing the app and handles elements that are off-screen or in scroll views.
   Only used for single left-clicks.

2. **Synthetic fallback**: If AX-native fails, finds the element position and
   performs a CGEvent-based click. Requires focusing the app first. Supports
   right-click, middle-click, and multi-click.

This dual approach maximizes compatibility across native and web applications.

### Focus Management

Action tools that need app focus (press, hotkey, scroll) require the `app`
parameter. Click and type use `FocusManager.withFocusRestore()` to:

1. Save the currently focused app
2. Focus the target app (if needed for synthetic fallback)
3. Perform the action
4. Restore focus to the original app

Perception tools work entirely from the background without focus changes.

### Element Cache

`ElementCache` provides a TTL-based cache (default 2 seconds) for recently
found elements. Since UI elements go stale quickly (windows resize, pages
scroll, content loads), the TTL is intentionally short. The cache is keyed
by locator hash and automatically evicts expired entries.

### Observer Manager

`ObserverManager` wraps AX notification subscriptions for event-driven waits.
It maintains a thread-safe registry of active subscriptions keyed by UUID
tokens, allowing clean subscription and unsubscription patterns. All
subscriptions are cleaned up on server shutdown.

### Transport Auto-Detection

The MCP server auto-detects the transport format from the first byte of input:
- `C` (0x43) indicates Content-Length framing (used by most MCP clients)
- `{` (0x7B) indicates NDJSON (used by simpler clients)

This removes the need for transport configuration and allows Daemon OS to
work with any MCP-compliant client without changes.

## AXorcist Integration

Daemon OS delegates all accessibility tree operations to
[AXorcist](https://github.com/steipete/AXorcist), a Swift library for
macOS accessibility automation. Key integration points:

- **Element discovery**: `Element.application()`, `findElement()`, `searchElements()`
- **Element inspection**: `title()`, `computedName()`, `role()`, `children()`
- **Actions**: `PerformActionCommand` for AXPress, `Element.click()` for synthetic
- **Locators**: `Locator` and `LocatorCriterion` for precise element targeting
- **Web support**: DOM id and class matching via AXorcist's web element support

Daemon OS builds `Locator` objects from tool parameters via `LocatorBuilder`,
which maps query/role/domId parameters to AXorcist's `LocatorCriterion` format.

## Concurrency Model

The project uses Swift 6 strict concurrency:
- `@MainActor` isolation for the MCP server (required by CoreGraphics/ScreenCaptureKit)
- `Sendable` conformance on all data types
- `NSLock`-based thread safety for shared mutable state (ElementCache, ObserverManager)
- `StrictConcurrency` experimental feature enabled
