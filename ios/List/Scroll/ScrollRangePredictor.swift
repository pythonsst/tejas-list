import UIKit

/// Predicts future visible range based on velocity.
/// PURE MATH — no UIKit, no state mutation.
struct ScrollRangePredictor {

  /// Predicts extra range in scroll direction.
  /// - Parameters:
  ///   - velocity: signed velocity (points/sec)
  ///   - viewportSize: visible viewport size
  ///   - itemCount: total items
  ///   - baseOverscan: current overscan
  /// - Returns: (leading, trailing) extra range
  static func predictOverscan(
    velocity: CGFloat,
    viewportSize: CGFloat,
    itemCount: Int,
    baseOverscan: Int
  ) -> (leading: Int, trailing: Int) {

    guard viewportSize > 0, itemCount > 0 else {
      return (0, 0)
    }

    let absVelocity = abs(velocity)

    // Velocity tiers (points/sec)
    let predictedItems: Int
    switch absVelocity {
    case 4000...:
      predictedItems = 20
    case 2500..<4000:
      predictedItems = 14
    case 1500..<2500:
      predictedItems = 8
    case 800..<1500:
      predictedItems = 4
    default:
      predictedItems = 0
    }

    // Direction-aware expansion
    if velocity > 0 {
      // Scrolling forward
      return (
        leading: 0,
        trailing: min(predictedItems, itemCount - 1)
      )
    } else if velocity < 0 {
      // Scrolling backward
      return (
        leading: min(predictedItems, itemCount - 1),
        trailing: 0
      )
    } else {
      return (0, 0)
    }
  }
}
