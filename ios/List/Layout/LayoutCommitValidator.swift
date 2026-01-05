import CoreGraphics

enum LayoutCommitValidator {

  static func validate(
    heights: [CGFloat],
    offsets: [CGFloat],
    total: CGFloat
  ) {
    #if DEBUG
    assert(heights.count == offsets.count)

    var sum: CGFloat = 0
    for i in 0..<heights.count {
      assert(offsets[i] == sum)
      sum += heights[i]
    }

    assert(abs(sum - total) < 0.5)
    #endif
  }
}
