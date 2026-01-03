import Foundation

enum ListDebugLog {

  /// Master switch (set false to silence everything)
  static let enabled = true

  static func info(_ message: @autoclosure () -> String) {
    guard enabled else { return }
    print("ℹ️ [TejasList]", message())
  }

  static func debug(_ message: @autoclosure () -> String) {
    guard enabled else { return }
    print("🐞 [TejasList]", message())
  }

  static func warn(_ message: @autoclosure () -> String) {
    guard enabled else { return }
    print("⚠️ [TejasList]", message())
  }
}
