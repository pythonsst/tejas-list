import UIKit

final class InitialWindowBootstrapper {

  private(set) var didBootstrap = false

  func bootstrapIfNeeded(
    itemCount: Int,
    estimatedItemHeight: CGFloat,
    viewportSize: CGFloat
  ) -> (start: Int, end: Int)? {
    guard !didBootstrap else { return nil }
    guard itemCount > 0, estimatedItemHeight > 0 else { return nil }

    let visibleCount = Int(ceil(viewportSize / estimatedItemHeight))
    let end = min(itemCount - 1, visibleCount + 2)

    didBootstrap = true
    return (0, end)
  }

  func reset() {
    didBootstrap = false
  }
}
