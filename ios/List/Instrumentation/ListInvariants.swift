import Foundation

enum ListInvariants {

  /// Call in DEBUG only
  static func assertMainThread(_ file: StaticString = #file, _ line: UInt = #line) {
    assert(Thread.isMainThread, "Must run on main thread", file: file, line: line)
  }

  static func assertRange(
    start: Int,
    end: Int,
    count: Int,
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) {
    assert(start >= 0, file: file, line: line)
    assert(end >= start, file: file, line: line)
    assert(end < count, file: file, line: line)
  }

  static func assertLayoutConsistency(
    heights: [CGFloat],
    offsets: [CGFloat],
    total: CGFloat,
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) {
    assert(heights.count == offsets.count, file: file, line: line)

    var sum: CGFloat = 0
    for i in 0..<heights.count {
      assert(offsets[i] == sum, file: file, line: line)
      sum += heights[i]
    }

    assert(abs(sum - total) < 0.5, file: file, line: line)
  }
}
