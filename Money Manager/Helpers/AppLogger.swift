@_exported import OSLog

/// Centralised loggers for each subsystem category.
/// Usage:
///   AppLogger.sync.error("Failed to pull expenses: \(error)")
///   AppLogger.data.warning("Category not found, falling back to Other")
///   AppLogger.auth.info("User logged in: \(username)")
///
/// Log levels (use the right one):
///   .debug    — verbose, only useful during development (stripped in release by default)
///   .info     — general flow milestones worth keeping
///   .notice   — notable but expected events (default level)
///   .warning  — something went wrong but the app recovered
///   .error    — operation failed, state may be inconsistent
///   .fault    — critical bug or data corruption
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.moneymanager"

    /// Sync, queue replay, network pull/push operations
    static let sync = Logger(subsystem: subsystem, category: "sync")

    /// Login, logout, session expiry, token management
    static let auth = Logger(subsystem: subsystem, category: "auth")

    /// SwiftData reads/writes, model mutations, category management
    static let data = Logger(subsystem: subsystem, category: "data")

    /// CSV/JSON export, file operations
    static let export = Logger(subsystem: subsystem, category: "export")
}
