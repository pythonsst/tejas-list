import CoreGraphics

/// Computes render-ahead visible window.
final class VisibleWindowPredictor {

  private let predictionTime: CGFloat = 0.2
  private let maxDistance: CGFloat = 1200

  func predict(
    currentOffset: CGFloat,
    viewport: CGFloat,
    kinematics: ScrollKinematics,
    offsets: [CGFloat]
  ) -> (start: Int, end: Int)? {

    guard !offsets.isEmpty else { return nil }

    let clampedVelocity =
      max(min(kinematics.velocity, maxDistance), -maxDistance)

    let predictedOffset =
      currentOffset + clampedVelocity * predictionTime

    let safeOffset = max(predictedOffset, 0)

    let start = BinarySearch.firstVisibleIndex(
      scrollOffset: safeOffset,
      offsets: offsets
    )

    let end = BinarySearch.lastVisibleIndex(
      scrollOffset: safeOffset,
      viewportSize: viewport,
      offsets: offsets
    )

    return start <= end ? (start, end) : nil
  }
}
