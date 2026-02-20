// Doctor.swift - Diagnostic tool for Daemon OS v2
//
// Non-interactive. Checks everything, reports issues, suggests fixes.
// Can auto-fix safe things (kill stale processes, recreate recipes dir).
//
// Usage: daemon doctor

import AppKit
import ApplicationServices
import AXorcist
import Foundation
import DaemonOS

struct Doctor {

    private var issueCount = 0
    private var warningCount = 0

    mutating func run() {
        print("")
        print("  Daemon OS Doctor")
        print("  ══════════════════════════════════")
        print("")

        checkBinary()
        checkAccessibility()
        checkScreenRecording()
        checkProcesses()
        checkMCPConfig()
        checkRecipes()
        checkAXTree()

        printSummary()
    }

    // MARK: - Binary

    private func checkBinary() {
        let path = ProcessInfo.processInfo.arguments[0]
        print("  Binary: \(path)")
        print("  Version: \(DaemonOS.version)")
        print("")
    }

    // MARK: - Accessibility

    private mutating func checkAccessibility() {
        if AXIsProcessTrusted() {
            print("  \u{2713} Accessibility: granted")
        } else {
            print("  \u{2717} Accessibility: NOT GRANTED")
            print("    Fix: System Settings > Privacy & Security > Accessibility")
            print("    Add your terminal app (\(detectHostApp()))")
            issueCount += 1
        }
    }

    // MARK: - Screen Recording

    private mutating func checkScreenRecording() {
        if ScreenCapture.hasPermission() {
            print("  \u{2713} Screen Recording: granted")
        } else {
            print("  ! Screen Recording: not granted (screenshots won't work)")
            print("    Fix: System Settings > Privacy & Security > Screen Recording")
            print("    Add your terminal app (\(detectHostApp()))")
            warningCount += 1
        }
    }

    // MARK: - Daemon Processes

    private mutating func checkProcesses() {
        let result = runShell("ps aux | grep '[d]aemon mcp' | awk '{print $2, $11, $12}'")
        let lines = result.output.split(separator: "\n").map(String.init)

        if lines.isEmpty {
            print("  \u{2713} Processes: no daemon MCP processes running")
        } else if lines.count == 1 {
            print("  \u{2713} Processes: 1 daemon MCP process (PID: \(lines[0].split(separator: " ").first ?? "?"))")
        } else {
            print("  \u{2717} Processes: \(lines.count) daemon MCP processes found (expect 0 or 1)")
            for line in lines {
                let parts = line.split(separator: " ")
                let pid = parts.first ?? "?"
                let path = parts.dropFirst().joined(separator: " ")
                print("    PID \(pid): \(path)")
            }
            print("    Fix: kill stale processes with:")
            for line in lines.dropFirst() {
                let pid = line.split(separator: " ").first ?? "?"
                print("      kill \(pid)")
            }
            issueCount += 1
        }
    }

    // MARK: - MCP Config

    /// Known MCP client config locations to check.
    private static let mcpClients: [(name: String, configPath: String, serverKey: String)] = [
        ("claude", NSHomeDirectory() + "/.claude.json", "daemon-os"),
        ("cursor", NSHomeDirectory() + "/.cursor/mcp.json", "daemon-os"),
    ]

    private mutating func checkMCPConfig() {
        // Check canonical config
        let canonicalPath = NSHomeDirectory() + "/.daemon-os/mcp-config.json"
        let hasCanonical = FileManager.default.fileExists(atPath: canonicalPath)

        // Check each known MCP client
        var foundInAny = false
        for client in Self.mcpClients {
            if let data = FileManager.default.contents(atPath: client.configPath),
               let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let mcpServers = config["mcpServers"] as? [String: Any],
               let serverConfig = mcpServers[client.serverKey] as? [String: Any]
            {
                let command = serverConfig["command"] as? String ?? "(unknown)"
                print("  \u{2713} MCP Config (\(client.name)): daemon-os configured")
                print("    Binary: \(command)")
                foundInAny = true
            }
        }

        if hasCanonical {
            print("  \u{2713} MCP Config (canonical): \(canonicalPath)")
            foundInAny = true
        }

        if !foundInAny {
            print("  \u{2717} MCP Config: daemon-os not configured in any MCP client")
            let binaryPath = resolveBinaryPath()
            print("    Fix: daemon setup")
            print("    Or manually add to your MCP client config:")
            print("      {")
            print("        \"type\": \"stdio\",")
            print("        \"command\": \"\(binaryPath)\",")
            print("        \"args\": [\"mcp\"]")
            print("      }")
            issueCount += 1
        }
    }

    // MARK: - Recipes

    private mutating func checkRecipes() {
        let recipesDir = NSHomeDirectory() + "/.daemon-os/recipes"
        if !FileManager.default.fileExists(atPath: recipesDir) {
            print("  \u{2717} Recipes: directory missing (~/.daemon-os/recipes/)")
            print("    Fix: daemon setup (installs bundled recipes)")
            issueCount += 1
            return
        }

        let recipes = RecipeStore.listRecipes()
        let files = (try? FileManager.default.contentsOfDirectory(atPath: recipesDir))?
            .filter { $0.hasSuffix(".json") } ?? []

        if files.count > recipes.count {
            let broken = files.count - recipes.count
            print("  ! Recipes: \(recipes.count) loaded, \(broken) failed to decode")
            // Find the broken ones
            let decoder = JSONDecoder()
            for file in files where file.hasSuffix(".json") {
                let path = (recipesDir as NSString).appendingPathComponent(file)
                if let data = FileManager.default.contents(atPath: path) {
                    do {
                        _ = try decoder.decode(Recipe.self, from: data)
                    } catch {
                        let name = (file as NSString).deletingPathExtension
                        print("    Broken: \(name) - \(error)")
                    }
                }
            }
            warningCount += 1
        } else {
            print("  \u{2713} Recipes: \(recipes.count) installed")
            for recipe in recipes.prefix(10) {
                print("    - \(recipe.name): \(recipe.steps.count) steps")
            }
        }
    }

    // MARK: - AX Tree

    private mutating func checkAXTree() {
        guard AXIsProcessTrusted() else {
            print("  - AX Tree: skipped (no permission)")
            return
        }

        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        var readable = 0
        var unreadable: [String] = []

        for app in apps {
            if Element.application(for: app.processIdentifier) != nil {
                readable += 1
            } else {
                if let name = app.localizedName {
                    unreadable.append(name)
                }
            }
        }

        if readable > 0 {
            print("  \u{2713} AX Tree: \(readable)/\(apps.count) apps readable")
            if !unreadable.isEmpty && unreadable.count <= 3 {
                print("    Unreadable: \(unreadable.joined(separator: ", ")) (may need focus)")
            }
        } else {
            print("  \u{2717} AX Tree: no apps readable")
            print("    This usually means Accessibility permission isn't working correctly.")
            print("    Fix: toggle the permission off and on in System Settings")
            issueCount += 1
        }
    }

    // MARK: - Summary

    private func printSummary() {
        print("")
        print("  ──────────────────────────────────")
        if issueCount == 0 && warningCount == 0 {
            print("  All checks passed. Daemon OS is healthy.")
        } else if issueCount == 0 {
            print("  \(warningCount) warning(s), no critical issues.")
        } else {
            print("  \(issueCount) issue(s), \(warningCount) warning(s).")
            print("  Fix the issues above, then run `daemon doctor` again.")
        }
        print("  ──────────────────────────────────")
        print("")
    }

    // MARK: - Helpers

    private func detectHostApp() -> String {
        if let termProgram = ProcessInfo.processInfo.environment["TERM_PROGRAM"] {
            switch termProgram.lowercased() {
            case "iterm.app", "iterm2": return "iTerm2"
            case "apple_terminal": return "Terminal"
            case "vscode": return "Visual Studio Code"
            case "cursor": return "Cursor"
            default: return termProgram
            }
        }
        return NSWorkspace.shared.frontmostApplication?.localizedName ?? "your terminal app"
    }

    private func resolveBinaryPath() -> String {
        for path in ["/opt/homebrew/bin/daemon", "/usr/local/bin/daemon"] {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return ProcessInfo.processInfo.arguments[0]
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
            return ShellResult(output: String(data: data, encoding: .utf8) ?? "", exitCode: process.terminationStatus)
        } catch {
            return ShellResult(output: "", exitCode: -1)
        }
    }
}
