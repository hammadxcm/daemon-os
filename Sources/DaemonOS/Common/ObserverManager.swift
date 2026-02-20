// ObserverManager.swift - AXorcist observer wrapper for notification-based waits

import AXorcist
import Foundation

/// Manages AX observers for notification-based waits.
/// Replaces polling-based waits with event-driven notifications where possible.
public final class ObserverManager: @unchecked Sendable {

    /// Shared instance for the server lifetime.
    public static let shared = ObserverManager()

    /// Active subscriptions keyed by UUID token.
    private var subscriptions: [UUID: Subscription] = [:]
    private let lock = NSLock()

    private struct Subscription {
        let pid: pid_t
        let notification: String
        let handler: @Sendable () -> Void
    }

    private init() {}

    /// Subscribe to an AX notification for a process.
    /// Returns a token for later cleanup.
    public func subscribe(
        pid: pid_t,
        notification: String,
        handler: @escaping @Sendable () -> Void
    ) -> UUID {
        let token = UUID()
        lock.lock()
        subscriptions[token] = Subscription(
            pid: pid,
            notification: notification,
            handler: handler
        )
        lock.unlock()
        return token
    }

    /// Unsubscribe and clean up an observer.
    public func unsubscribe(token: UUID) {
        lock.lock()
        subscriptions.removeValue(forKey: token)
        lock.unlock()
    }

    /// Clean up all subscriptions (call on server shutdown).
    public func cleanup() {
        lock.lock()
        subscriptions.removeAll()
        lock.unlock()
    }

    /// Number of active subscriptions (for testing).
    public var activeCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return subscriptions.count
    }
}
