import UIKit

/**
 * ListCoordinator
 *
 * Central coordinator for the native list.
 * Connects layout, scrolling, and view mounting.
 */
final class ListCoordinator {

  /// Root view exposed to the Hybrid layer
  let rootView = ListRootView()

  /// Emits currently visible item range
  var onVisibleRangeChange: ((Int, Int) -> Void)?

  private let layoutEngine = ListLayoutEngine()
  private let scrollHandler = ListScrollHandler()

  init() {
    // Scroll math needs layout data
    scrollHandler.layout = layoutEngine

    // Build layout once bounds are known
    rootView.onLayoutReady = { [weak self] in
      self?.rebuildLayoutAndMount()
    }

    // Forward scroll events
    rootView.onScroll = { [weak self] offsetY, height in
      self?.scrollHandler.handleScroll(
        offsetY: offsetY,
        viewportHeight: height
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

      if self.layoutEngine.offset(at: index)
        < self.rootView.scrollView.contentOffset.y {

        self.rootView.scrollView.contentOffset.y += delta
      }

      self.rootView.setContentHeight(
        self.layoutEngine.totalHeight
      )

      scrollHandler.reset()
    }
  }

  /// Builds layout and guarantees first visible cells are mounted
  func rebuildLayoutAndMount() {
    guard
      layoutEngine.itemCount > 0,
      layoutEngine.estimatedItemHeight > 0,
      rootView.bounds.height > 0
    else { return }

    layoutEngine.build()
    rootView.setContentHeight(layoutEngine.totalHeight)
    scrollHandler.reset()

    scrollHandler.handleScroll(
      offsetY: rootView.scrollView.contentOffset.y,
      viewportHeight: rootView.bounds.height
    )
  }

  /// Scrolls to a specific item index
  func scrollToIndex(_ index: Int, animated: Bool) {
    guard index >= 0, index < layoutEngine.count else { return }

    rootView.scrollView.setContentOffset(
      CGPoint(x: 0, y: layoutEngine.offset(at: index)),
      animated: animated
    )
  }

  func setItemCount(_ count: Int) {
    layoutEngine.itemCount = count
  }

  func setEstimatedItemHeight(_ height: CGFloat) {
    layoutEngine.estimatedItemHeight = height
  }
}
