import UIKit
import NitroModules

/**
 * HybridTejasList
 *
 * Nitro-facing wrapper.
 * - Exposes props to JS
 * - Delegates all logic to ListCoordinator
 *
 * 🚫 No layout math
 * 🚫 No UIKit logic
 */
final class HybridTejasList: HybridTejasListSpec {

  // MARK: - Core engine (single source of truth)

  private let coordinator = ListCoordinator()

  // MARK: - Nitro required props (MUST be public)

  var itemCount: Double = 0 {
    didSet {
      coordinator.setItemCount(Int(itemCount))
    }
  }

  var estimatedItemHeight: Double = 0 {
    didSet {
      coordinator.setEstimatedItemHeight(
        CGFloat(estimatedItemHeight)
      )
    }
  }

  var onVisibleRangeChange: ((Double, Double) -> Void)? {
    didSet {
      coordinator.onVisibleRangeChange = { [weak self] start, end in
        self?.onVisibleRangeChange?(
          Double(start),
          Double(end)
        )
      }
    }
  }

  // MARK: - View (Nitro requirement)

  var view: UIView {
    coordinator.rootView
  }

  // MARK: - Nitro lifecycle hooks

  /// Called by Nitro when props are committed
  func reload() throws {
    // Ensure layout + first mount
    coordinator.rebuildLayoutAndMount()
  }

  /// JS → Native scroll API
  func scrollToIndex(
    index: Double,
    animated: Bool
  ) throws {
    coordinator.scrollToIndex(
      Int(index),
      animated: animated
    )
  }
}
