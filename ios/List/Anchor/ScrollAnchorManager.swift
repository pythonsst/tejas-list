import CoreGraphics

/// Computes scroll offset correction during relayout.
struct ScrollAnchorManager {

  static func offsetDelta(
    anchorIndex: Int,
    oldOffsets: [CGFloat],
    newOffsets: [CGFloat]
  ) -> CGFloat {

    guard
      anchorIndex < oldOffsets.count,
      anchorIndex < newOffsets.count
    else { return 0 }

    return newOffsets[anchorIndex] - oldOffsets[anchorIndex]
  }
}
