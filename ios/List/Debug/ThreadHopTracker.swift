import Foundation

enum ThreadHopTracker {

  static func assertMainThread(
    _ message: String = ""
  ) {
    assert(
      Thread.isMainThread,
      "❌ Thread hop detected. \(message)"
    )
  }
}
