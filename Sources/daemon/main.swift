// main.swift - Daemon OS v2 CLI entry point
//
// Thin CLI:
//   daemon mcp       Start the MCP server
//   daemon setup     Interactive setup wizard
//   daemon doctor    Diagnose issues and suggest fixes
//   daemon status    Quick health check
//   daemon version   Print version

import AppKit
import ApplicationServices
import Foundation
import DaemonOS

// Force CoreGraphics server connection initialization.
// ScreenCaptureKit requires a CG connection to the window server.
_ = CGMainDisplayID()

let args = CommandLine.arguments.dropFirst()
let command = args.first ?? "help"

switch command {
case "mcp":
    let server = MCPServer()
    server.run()

case "setup":
    let wizard = SetupWizard()
    wizard.run()

case "doctor":
    var doctor = Doctor()
    doctor.run()

case "status":
    printStatus()

case "version", "--version", "-v":
    print("Daemon OS v\(DaemonOS.version)")

case "help", "--help", "-h":
    printUsage()

default:
    fputs("Unknown command: \(command)\n", stderr)
    printUsage()
    exit(1)
}

// MARK: - Status

func printStatus() {
    print("Daemon OS v\(DaemonOS.version)")
    print("")

    let hasAX = AXIsProcessTrusted()
    print("Accessibility: \(hasAX ? "granted" : "NOT GRANTED")")
    if !hasAX {
        print("  Run: daemon setup")
    }

    let hasScreenRecording = ScreenCapture.hasPermission()
    print("Screen Recording: \(hasScreenRecording ? "granted" : "not granted")")

    let recipes = RecipeStore.listRecipes()
    print("Recipes: \(recipes.count) installed")

    let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
    print("Running apps: \(apps.count)")

    print("")
    print(hasAX ? "Status: Ready" : "Status: Run `daemon setup` first")
}

// MARK: - Usage

func printUsage() {
    print("""
    Daemon OS v\(DaemonOS.version) - Accessibility-tree MCP server for AI agents

    Usage: daemon <command>

    Commands:
      mcp       Start the MCP server
      setup     Interactive setup wizard (first-time configuration)
      doctor    Diagnose issues and suggest fixes
      status    Quick health check
      version   Print version

    Get started:
      daemon setup     Configure permissions and MCP
      daemon doctor    Check if everything is working

    Daemon OS gives AI agents eyes and hands on macOS.
    """)
}
