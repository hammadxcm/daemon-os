// SetupWizard.swift - Interactive first-run setup for Daemon OS v2
//
// Walks the user through:
//   1. Detect host app (iTerm2, VS Code, Cursor, Terminal)
//   2. Accessibility permission (opens System Settings to exact pane)
//   3. Screen Recording permission (optional, for screenshots)
//   4. MCP configuration for supported MCP clients
//   5. Install bundled recipes
//   6. Self-test verification
//
// Usage: daemon setup

import AppKit
import ApplicationServices
import AXorcist
import Foundation
import DaemonOS

struct SetupWizard {

    func run() {
        printBanner()

        // Step 1: Detect host app
        let hostApp = detectHostApp()
        printStep(1, "Host Application")
        print("  Detected: \(hostApp)")
        print("  This app needs Accessibility permission to use Daemon OS.")
        print("")

        // Step 2: Accessibility permission
        let hasAccess = checkAccessibility(hostApp: hostApp)

        // Step 3: Screen Recording (optional)
        let hasScreenRecording = checkScreenRecording(hostApp: hostApp)

        // Step 4: MCP configuration
        configureMCP()

        // Step 5: Install recipes
        installRecipes()

        // Step 6: Self-test
        let verified = selfTest(hasAccess: hasAccess, hasScreenRecording: hasScreenRecording)

        // Summary
        printSummary(
            hostApp: hostApp,
            accessibility: hasAccess,
            screenRecording: hasScreenRecording,
            verified: verified
        )
    }

    // MARK: - Step 1: Detect Host App

    private func detectHostApp() -> String {
        // Check TERM_PROGRAM environment variable (set by most terminals)
        if let termProgram = ProcessInfo.processInfo.environment["TERM_PROGRAM"] {
            switch termProgram.lowercased() {
            case "iterm.app", "iterm2": return "iTerm2"
            case "apple_terminal": return "Terminal"
            case "vscode": return "Visual Studio Code"
            case "cursor": return "Cursor"
            case "warp": return "Warp"
            case "alacritty": return "Alacritty"
            case "kitty": return "kitty"
            default: return termProgram
            }
        }

        // Check if running inside VS Code or Cursor by looking at parent process
        if let vscodeEnv = ProcessInfo.processInfo.environment["VSCODE_PID"] {
            _ = vscodeEnv
            return "Visual Studio Code"
        }

        // Fallback: check the frontmost app
        if let frontApp = NSWorkspace.shared.frontmostApplication?.localizedName {
            return frontApp
        }

        return "your terminal app"
    }

    // MARK: - Step 2: Accessibility Permission

    private func checkAccessibility(hostApp: String) -> Bool {
        printStep(2, "Accessibility Permission")

        if AXIsProcessTrusted() {
            // Verify with actual AX tree read
            let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
            var axCount = 0
            for app in apps {
                if Element.application(for: app.processIdentifier) != nil {
                    axCount += 1
                }
            }

            if axCount > 0 {
                printOK("Granted (\(axCount) apps accessible)")
                return true
            }
        }

        // Not granted
        print("  Daemon OS reads the accessibility tree to see and operate apps.")
        print("  \(hostApp) needs the Accessibility permission.")
        print("")
        print("  Opening System Settings...")
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        print("")
        print("  Add \"\(hostApp)\" to the Accessibility list.")
        print("  You may need to toggle it off and on if it's already there.")
        print("")

        // Retry loop
        for attempt in 1...3 {
            print("  Press Enter after granting permission (\(attempt)/3)...")
            _ = readLine()

            if AXIsProcessTrusted() {
                printOK("Granted")
                return true
            }

            if attempt < 3 {
                print("  Still not granted. Make sure you added \"\(hostApp)\".")
            }
        }

        printFail("Not granted")
        print("  Grant permission in System Settings > Privacy & Security > Accessibility")
        print("  Then run `daemon setup` again.")
        print("")
        return false
    }

    // MARK: - Step 3: Screen Recording Permission

    private func checkScreenRecording(hostApp: String) -> Bool {
        printStep(3, "Screen Recording Permission (optional)")

        if ScreenCapture.hasPermission() {
            printOK("Granted")
            return true
        }

        print("  Screenshots are optional but useful for visual debugging.")
        print("  \(hostApp) needs Screen Recording permission.")
        print("")
        print("  Set it up now? (y/N) ", terminator: "")
        fflush(stdout)

        guard let answer = readLine()?.lowercased(), answer == "y" || answer == "yes" else {
            printOK("Skipped (you can set this up later)")
            return false
        }

        ScreenCapture.requestPermission()
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        print("")
        print("  Add \"\(hostApp)\" to the Screen Recording list.")
        print("  Press Enter after granting...")
        _ = readLine()

        if ScreenCapture.hasPermission() {
            printOK("Granted")
            return true
        }

        printFail("Not granted (you can run `daemon setup` again later)")
        return false
    }

    // MARK: - Step 4: MCP Configuration

    /// Known MCP client config locations.
    /// Each entry is (clientName, configPath, serverKey).
    private static let mcpClients: [(name: String, configPath: String, serverKey: String)] = [
        ("claude", NSHomeDirectory() + "/.claude.json", "daemon-os"),
        ("cursor", NSHomeDirectory() + "/.cursor/mcp.json", "daemon-os"),
    ]

    private func configureMCP() {
        printStep(4, "MCP Configuration")

        let binaryPath = resolveBinaryPath()
        let canonicalConfigPath = NSHomeDirectory() + "/.daemon-os/mcp-config.json"

        // Write canonical config at ~/.daemon-os/mcp-config.json
        writeCanonicalConfig(binaryPath: binaryPath, canonicalConfigPath: canonicalConfigPath)

        // Detect and configure each known MCP client
        var configuredAny = false
        for client in Self.mcpClients {
            let configured = configureClient(
                clientName: client.name,
                configPath: client.configPath,
                serverKey: client.serverKey,
                binaryPath: binaryPath
            )
            if configured {
                configuredAny = true
            }
        }

        if !configuredAny {
            print("  No supported MCP clients detected.")
            print("  Canonical config written to: \(canonicalConfigPath)")
            print("")
            print("  To connect an MCP client, add this server entry:")
            print("    {")
            print("      \"type\": \"stdio\",")
            print("      \"command\": \"\(binaryPath)\",")
            print("      \"args\": [\"mcp\"]")
            print("    }")
            print("")
        }

        printOK("Configured")
    }

    /// Writes the canonical Daemon OS MCP config to ~/.daemon-os/mcp-config.json.
    private func writeCanonicalConfig(binaryPath: String, canonicalConfigPath: String) {
        let daemonDir = NSHomeDirectory() + "/.daemon-os"
        try? FileManager.default.createDirectory(atPath: daemonDir, withIntermediateDirectories: true)

        let serverEntry: [String: Any] = [
            "type": "stdio",
            "command": binaryPath,
            "args": ["mcp"],
        ]
        let config: [String: Any] = [
            "mcpServers": ["daemon-os": serverEntry]
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: URL(fileURLWithPath: canonicalConfigPath))
        } catch {
            print("  Warning: could not write canonical config to \(canonicalConfigPath)")
        }
    }

    /// Attempts to configure a single MCP client. Returns true if the client was detected
    /// (regardless of whether configuration was already present or newly written).
    private func configureClient(clientName: String, configPath: String, serverKey: String, binaryPath: String) -> Bool {
        // Check if the client config file or parent directory exists
        let parentDir = (configPath as NSString).deletingLastPathComponent
        let configExists = FileManager.default.fileExists(atPath: configPath)
        let parentExists = FileManager.default.fileExists(atPath: parentDir)

        // If neither the config file nor its parent directory exists, the client probably isn't installed
        if !configExists && !parentExists && parentDir != NSHomeDirectory() {
            return false
        }

        // Read existing config if present
        var config: [String: Any] = [:]
        if let data = FileManager.default.contents(atPath: configPath),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            config = existing
        }

        // Check if already configured
        if let mcpServers = config["mcpServers"] as? [String: Any],
           mcpServers[serverKey] != nil
        {
            print("  \(clientName): already configured")
            return true
        }

        // Write config
        var mcpServers = config["mcpServers"] as? [String: Any] ?? [:]
        mcpServers[serverKey] = [
            "type": "stdio",
            "command": binaryPath,
            "args": ["mcp"],
        ]
        config["mcpServers"] = mcpServers

        do {
            try FileManager.default.createDirectory(atPath: parentDir, withIntermediateDirectories: true)
            let jsonData = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: URL(fileURLWithPath: configPath))
            print("  \(clientName): configured (\(configPath))")
        } catch {
            print("  \(clientName): could not write config to \(configPath)")
        }

        return true
    }

    // MARK: - Step 5: Install Recipes

    private func installRecipes() {
        printStep(5, "Bundled Recipes")

        let recipesDir = NSHomeDirectory() + "/.daemon-os/recipes"
        try? FileManager.default.createDirectory(atPath: recipesDir, withIntermediateDirectories: true)

        // Find bundled recipes in the repo's recipes/ directory
        let bundledDir = findBundledRecipesDir()
        var installed = 0

        if let bundledDir, let files = try? FileManager.default.contentsOfDirectory(atPath: bundledDir) {
            for file in files where file.hasSuffix(".json") {
                let srcPath = (bundledDir as NSString).appendingPathComponent(file)
                let dstPath = (recipesDir as NSString).appendingPathComponent(file)

                if FileManager.default.fileExists(atPath: dstPath) {
                    let name = (file as NSString).deletingPathExtension
                    print("  \(name) - already installed")
                    installed += 1
                    continue
                }

                do {
                    try FileManager.default.copyItem(atPath: srcPath, toPath: dstPath)
                    let name = (file as NSString).deletingPathExtension
                    print("  \(name) - installed")
                    installed += 1
                } catch {
                    print("  \(file) - failed to install")
                }
            }
        }

        // Count total recipes
        let total = RecipeStore.listRecipes().count
        printOK("\(total) recipe(s) available")
    }

    // MARK: - Step 6: Self-Test

    private func selfTest(hasAccess: Bool, hasScreenRecording: Bool) -> Bool {
        printStep(6, "Self-Test")

        guard hasAccess else {
            printFail("Skipped (needs Accessibility permission)")
            return false
        }

        // Test 1: Read AX tree
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        var readable = 0
        for app in apps.prefix(5) {
            if Element.application(for: app.processIdentifier) != nil {
                readable += 1
            }
        }

        if readable > 0 {
            print("  AX tree: \(readable) apps readable")
        } else {
            printFail("Cannot read accessibility tree")
            return false
        }

        // Test 2: Screenshot (if permission granted)
        if hasScreenRecording {
            print("  Screenshot: available")
        } else {
            print("  Screenshot: skipped (no Screen Recording permission)")
        }

        printOK("All tests passed")
        return true
    }

    // MARK: - Summary

    private func printSummary(hostApp: String, accessibility: Bool, screenRecording: Bool, verified: Bool) {
        print("")
        print("  ══════════════════════════════════")
        if accessibility && verified {
            print("  Daemon OS is ready!")
            print("")
            print("  Start a new MCP client session to connect.")
            print("  Then try: \"Send an email via Gmail\"")
            print("  Or:       \"Search arxiv for transformers\"")
        } else {
            print("  Setup incomplete.")
            print("")
            if !accessibility {
                print("  Fix: Grant Accessibility permission to \(hostApp)")
            }
            print("  Then run `daemon setup` again.")
        }
        print("  ══════════════════════════════════")
        print("")
    }

    // MARK: - Helpers

    private func printBanner() {
        print("")
        print("  Daemon OS v\(DaemonOS.version) Setup")
        print("  ══════════════════════════════════")
        print("")
    }

    private func printStep(_ n: Int, _ title: String) {
        print("  \(n). \(title)")
    }

    private func printOK(_ message: String) {
        print("     \u{2713} \(message)")
        print("")
    }

    private func printFail(_ message: String) {
        print("     \u{2717} \(message)")
        print("")
    }

    private func openSystemSettings(_ url: String) {
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
    }

    private func resolveBinaryPath() -> String {
        // Check common install locations
        let candidates = [
            "/opt/homebrew/bin/daemon",
            "/usr/local/bin/daemon",
            ProcessInfo.processInfo.arguments[0],
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return ProcessInfo.processInfo.arguments[0]
    }

    private func findBundledRecipesDir() -> String? {
        let binaryPath = ProcessInfo.processInfo.arguments[0]
        let binaryDir = (binaryPath as NSString).deletingLastPathComponent

        // Homebrew: /opt/homebrew/share/daemon-os/recipes/
        let brewPaths = [
            "/opt/homebrew/share/daemon-os/recipes",
            "/usr/local/share/daemon-os/recipes",
        ]
        for path in brewPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // Development: .build/debug/daemon -> project root/recipes/
        let projectRoot = ((binaryDir as NSString)
            .deletingLastPathComponent as NSString)
            .deletingLastPathComponent
        let recipesPath = (projectRoot as NSString).appendingPathComponent("recipes")
        if FileManager.default.fileExists(atPath: recipesPath) {
            return recipesPath
        }

        // Sibling: next to the binary
        let siblingPath = (binaryDir as NSString).appendingPathComponent("recipes")
        if FileManager.default.fileExists(atPath: siblingPath) {
            return siblingPath
        }

        return nil
    }

    private struct ShellResult {
        let output: String
        let exitCode: Int32
    }

    private func runShell(_ command: String) -> ShellResult {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe
        let env = ProcessInfo.processInfo.environment
        process.environment = env

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return ShellResult(output: output, exitCode: process.terminationStatus)
        } catch {
            return ShellResult(output: "", exitCode: -1)
        }
    }
}
