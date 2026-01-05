import CoreGraphics

/// Describes scroll physics for a single frame.
struct ScrollKinematics {

  /// Signed velocity (points / second)
  let velocity: CGFloat

  /// Scroll direction
  let direction: ScrollAxisDirection

  /// Whether scroll is considered fast
  let isFast: Bool

  /// Predicted future offset (render-ahead)
  let predictedOffset: CGFloat
}
