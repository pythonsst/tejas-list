import UIKit
import NitroModules

/// Nitro-facing wrapper.
/// Receives JS props and forwards them to the native coordinator.
final class HybridTejasList: HybridTejasListSpec {

  private let coordinator = ListCoordinator()
  private var needsReload = false

  // MARK: - JS Props

  var itemStyle: ItemStyle? {
    didSet {
      coordinator.setItemStyle(itemStyle)
      needsReload = true
    }
  }

  var scrollDirection: ScrollDirection? {
    didSet {
      coordinator.setScrollDirection(scrollDirection)
      needsReload = true
    }
  }

  var itemCount: Double = 0 {
    didSet {
      coordinator.setItemCount(Int(itemCount))
      needsReload = true
    }
  }

  var estimatedItemHeight: Double = 0 {
    didSet {
      coordinator.setEstimatedItemHeight(CGFloat(estimatedItemHeight))
      needsReload = true
    }
  }

  // MARK: - Layout Spacing

  var rowSpacing: Double? {
    didSet {
      coordinator.setRowSpacing(CGFloat(rowSpacing ?? 0))
      needsReload = true
    }
  }

  var columnSpacing: Double? {
    didSet {
      coordinator.setColumnSpacing(CGFloat(columnSpacing ?? 0))
      needsReload = true
    }
  }

  // MARK: - Item String (NEW, STATIC)

  /// Static row label prefix (e.g. "Row")
  var itemString: String? {
    didSet {
      coordinator.setItemString(itemString)
      needsReload = true
    }
  }

  // MARK: - Callbacks

  var onVisibleRangeChange: ((Double, Double) -> Void)? {
    didSet {
      coordinator.onVisibleRangeChange = { [weak self] start, end in
        self?.onVisibleRangeChange?(Double(start), Double(end))
      }
    }
  }

  // MARK: - Nitro View

  var view: UIView {
    coordinator.rootView
  }

  // MARK: - Nitro Lifecycle

  func beforeUpdate() {}

  func afterUpdate() {
    guard needsReload else { return }
    needsReload = false
    coordinator.reload()
  }

  // MARK: - Methods

  func scrollToIndex(index: Double, animated: Bool) throws {
    coordinator.scrollToIndex(Int(index), animated: animated)
  }
}
