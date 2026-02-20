# Contributing

This guide covers the development setup, code standards, testing practices,
and pull request process for Daemon OS.

## Development Setup

### Clone and Build

```bash
git clone https://github.com/daemon-os/daemon-os.git
cd daemon-os
swift build
```

### Set Up Git Hooks

The repository includes pre-commit hooks for linting and formatting:

```bash
make setup-hooks
```

This configures Git to use the hooks in `.githooks/`.

### Dependencies

The project has one external dependency:

- [AXorcist](https://github.com/steipete/AXorcist) -- macOS accessibility tree library

Swift Package Manager resolves this automatically on first build.

### IDE Setup

Open the project in Xcode:

```bash
open Package.swift
```

Or use any editor with Swift LSP support. The project uses Swift 6.2 with
strict concurrency enabled.

## Code Standards

### SwiftLint

Lint the codebase:

```bash
make lint
```

All warnings are treated as errors (`--strict` flag). Fix all lint issues
before committing.

### SwiftFormat

Format the codebase:

```bash
make format
```

Check formatting without modifying files:

```bash
make format-check
```

### Concurrency

The project uses Swift 6 strict concurrency. All public types must be
`Sendable`. The MCP server uses `@MainActor` isolation. Shared mutable
state must use `NSLock` or other thread-safe patterns.

### Code Organization

- **Modules** map to tool categories: Perception, Actions, Wait, Recipes
- **Facades** (`Perception.swift`, `Actions.swift`) provide the public API
- **Handlers** (`ClickHandler.swift`, `TypeHandler.swift`) contain implementation
- **Common/** holds shared types, helpers, and protocols
- **Server/** handles MCP protocol concerns only

New tools should follow the existing pattern:
1. Add the tool definition to `MCPTools.swift`
2. Add the dispatch case to `MCPDispatch.swift`
3. Implement in the appropriate module
4. Add tests

## Testing

### Unit Tests

```bash
make test
```

Runs the `DaemonOSTests` test target. These tests do not require Accessibility
permission and can run in CI.

### Integration Tests

```bash
make test-integration
```

Integration tests interact with real applications and require both Accessibility
and Screen Recording permissions. Run these locally before submitting PRs that
change action or perception logic.

### All Tests

```bash
make test-all
```

### Code Coverage

```bash
make coverage
```

Generates a coverage report using `llvm-cov`. The project targets 100% coverage
for all non-UI code paths. New code must include tests that cover all branches.

## Pull Request Process

1. **Branch**: Create a feature branch from `main`
2. **Implement**: Make your changes following the code standards above
3. **Test**: Run `make test` (and `make test-integration` if applicable)
4. **Lint**: Run `make lint` and `make format-check`
5. **Coverage**: Run `make coverage` and verify no regressions
6. **Commit**: Write clear, descriptive commit messages
7. **PR**: Open a pull request against `main` with:
   - A summary of what changed and why
   - Test plan or verification steps
   - Any relevant issue references

### PR Review Checklist

- All tests pass
- No lint warnings
- Code is formatted
- New features have tests
- Public APIs have documentation comments
- No breaking changes to MCP tool schemas (or migration documented)

## Release Process

Releases are tagged on `main`. Version is updated in `Types.swift`:

```swift
public static let version = "3.0.0"
```

Build the release binary:

```bash
make build-release
```

## Project Structure

```
daemon-os/
  Package.swift              Swift package manifest
  Makefile                   Build, test, lint, format commands
  DAEMON-MCP.md              Agent instructions (shipped with binary)
  Sources/
    DaemonOS/                Library target (all MCP tools)
    daemon/                  Executable target (CLI entry point)
  Tests/
    DaemonOSTests/           Unit and integration tests
  .githooks/
    pre-commit               Pre-commit hook (lint + format check)
```
