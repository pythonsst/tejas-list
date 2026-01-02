import Foundation

enum ThreadAssertions {

  static func assertMainThread(_ message: String = "") {
    assert(Thread.isMainThread, "❌ Must be on main thread. \(message)")
  }
}
