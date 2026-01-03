import Foundation

/// Centralized debug logger for TejasList.
/// IMPORTANT:
/// - Must NOT be used inside hot paths (per-frame, scroll, layout loops)
/// - Safe to leave calls in production (zero cost when disabled)
enum ListDebugLog {

  // MARK: - Log Level

  enum Level {
    case off        // Production default
    case error
    case info
    case debug
  }

  /// Change this in ONE place to control all logs
  static var level: Level = .off

  // MARK: - Logging APIs

  @inline(__always)
  static func debug(
    _ message: @autoclosure () -> String
  ) {
    guard level == .debug else { return }
    print("🟦 [TejasList][DEBUG]", message())
  }

  @inline(__always)
  static func info(
    _ message: @autoclosure () -> String
  ) {
    guard level == .debug || level == .info else { return }
    print("🟩 [TejasList][INFO]", message())
  }

  @inline(__always)
  static func error(
    _ message: @autoclosure () -> String
  ) {
    guard level != .off else { return }
    print("🟥 [TejasList][ERROR]", message())
  }
}
