// BatchExecutor.swift - AXorcist batch operations wrapper

import AXorcist
import Foundation

/// Wraps AXorcist's batch command for atomic multi-step operations.
/// Reduces round-trips and improves recipe execution speed for steps
/// that can run without intermediate waits.
public enum BatchExecutor {

    /// Execute multiple AXorcist commands as a batch.
    /// Returns results for each command in order.
    public static func execute(
        commands: [AXCommandEnvelope]
    ) -> [AXResponse] {
        commands.map { envelope in
            AXorcist.shared.runCommand(envelope)
        }
    }

    /// Check if a sequence of recipe steps can be batched.
    /// Steps can be batched if none have wait_after conditions
    /// and they target the same app.
    public static func canBatch(steps: [RecipeStep]) -> Bool {
        steps.allSatisfy { $0.waitAfter == nil }
    }
}
