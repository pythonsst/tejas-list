import UIKit

/**
 * ListCoordinator
 *
 * Central coordinator for the native list.
 * Translates props into native behavior and orchestrates:
 * - layout
 * - scrolling
 * - cell mounting
 */
final class ListCoordinator {

  /// Root view exposed to the Hybrid layer
  let rootView = ListRootView()

  /// Emits currently visible item range
  var onVisibleRangeChange: ((Int, Int) -> Void)?

  private let layoutEngine = ListLayoutEngine()
  private let scrollHandler = ListScrollHandler()

  /// Current scroll axis (default = vertical)
  private var scrollAxis: ScrollAxis = .vertical

  init() {
    // Scroll math needs layout data
    scrollHandler.layout = layoutEngine

    // Build layout once bounds are known
    rootView.onLayoutReady = { [weak self] in
      self?.rebuildLayoutAndMount()
    }

    // Forward scroll events (axis-agnostic)
    rootView.onScroll = { [weak self] offset, viewportSize in
      self?.scrollHandler.handleScroll(
        offset: offset,
        viewportSize: viewportSize
      )
    }

    // Mount cells when visible range changes
    scrollHandler.onVisibleRangeChange = { [weak self] start, end in
      guard let self else { return }

      self.rootView.mountCells(
        start: start,
        end: end,
        layout: self.layoutEngine
      )

      self.onVisibleRangeChange?(start, end)
    }

    // Handle dynamic height changes without breaking scroll position
    rootView.onCellHeightChange = { [weak self] index, height in
      guard let self else { return }

      let delta = self.layoutEngine.updateHeight(
        at: index,
        height: height
      )

      guard delta != 0 else { return }

      let currentOffset =
        self.scrollAxis == .horizontal
          ? self.rootView.scrollView.contentOffset.x
          : self.rootView.scrollView.contentOffset.y

      if self.layoutEngine.offset(at: index) < currentOffset {
        if self.scrollAxis == .horizontal {
          self.rootView.scrollView.contentOffset.x += delta
        } else {
          self.rootView.scrollView.contentOffset.y += delta
        }
      }

      self.rootView.setContentSize(
        self.scrollAxis == .horizontal
          ? CGSize(
              width: self.layoutEngine.totalHeight,
              height: self.rootView.bounds.height
            )
          : CGSize(
              width: self.rootView.bounds.width,
              height: self.layoutEngine.totalHeight
            )
      )

      self.scrollHandler.reset()
    }
  }

  // MARK: - Public API (called from HybridTejasList)

  func setScrollDirection(_ direction: ScrollDirection?) {
    scrollAxis = (direction == .horizontal) ? .horizontal : .vertical

    scrollHandler.scrollAxis = scrollAxis
    rootView.setScrollAxis(scrollAxis)

    scrollHandler.reset()
    rebuildLayoutAndMount()
  }
  
  func reload() {
    scrollHandler.reset()
    rebuildLayoutAndMount()
  }


  func setItemCount(_ count: Int) {
    layoutEngine.itemCount = count
  }

  func setEstimatedItemHeight(_ height: CGFloat) {
    layoutEngine.estimatedItemHeight = height
  }

  /// Scrolls to a specific item index
  func scrollToIndex(_ index: Int, animated: Bool) {
    guard index >= 0, index < layoutEngine.count else { return }

    let targetOffset = layoutEngine.offset(at: index)

    if scrollAxis == .horizontal {
      rootView.scrollView.setContentOffset(
        CGPoint(x: targetOffset, y: 0),
        animated: animated
      )
    } else {
      rootView.scrollView.setContentOffset(
        CGPoint(x: 0, y: targetOffset),
        animated: animated
      )
    }
  }

  // MARK: - Internal

  /// Builds layout and guarantees first visible cells are mounted
  private func rebuildLayoutAndMount() {
    guard
      layoutEngine.itemCount > 0,
      layoutEngine.estimatedItemHeight > 0
    else { return }

    layoutEngine.build()

    let viewportSize =
      scrollAxis == .horizontal
        ? rootView.bounds.width
        : rootView.bounds.height

    rootView.setContentSize(
      scrollAxis == .horizontal
        ? CGSize(
            width: layoutEngine.totalHeight,
            height: rootView.bounds.height
          )
        : CGSize(
            width: rootView.bounds.width,
            height: layoutEngine.totalHeight
          )
    )

    scrollHandler.reset()

    let offset =
      scrollAxis == .horizontal
        ? rootView.scrollView.contentOffset.x
        : rootView.scrollView.contentOffset.y

    scrollHandler.handleScroll(
      offset: offset,
      viewportSize: viewportSize
    )
  }
}
