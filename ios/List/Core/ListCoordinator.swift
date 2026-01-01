import UIKit

/**
 * ListCoordinator
 *
 * Orchestrates:
 * - Scroll events → visible range calculation
 * - Layout engine → offsets & heights
 * - Root view → mounting & recycling cells
 *
 * 🚫 No Nitro
 * 🚫 No UIKit math
 * 🚫 No heavy logic
 */
final class ListCoordinator {

  // MARK: - Public

  let rootView = ListRootView()

  /// Native → JS callback
  var onVisibleRangeChange: ((Int, Int) -> Void)?

  // MARK: - Core engines

  private let layoutEngine = ListLayoutEngine()
  private let scrollHandler = ListScrollHandler()

  // MARK: - Init

  init() {
    // 1️⃣ Layout ready
    rootView.onLayoutReady = { [weak self] in
      self?.rebuildLayout()
    }

    // 2️⃣ Scroll → visible range
    rootView.onScroll = { [weak self] offsetY, viewportHeight in
      self?.scrollHandler.handleScroll(
        offsetY: offsetY,
        viewportHeight: viewportHeight
      )
    }

    // 3️⃣ Visible range → mount cells
    scrollHandler.onVisibleRangeChange = { [weak self] start, end in
      guard let self else { return }

      self.rootView.mountCells(
        start: start,
        end: end,
        layout: self.layoutEngine
      )

      self.onVisibleRangeChange?(start, end)
    }

    // 4️⃣ Cell height measurement → anchor-safe update
    rootView.onCellHeightChange = { [weak self] index, height in
      guard let self else { return }

      let delta = self.layoutEngine.updateHeight(
        at: index,
        height: height
      )

      guard delta != 0 else { return }

      // Scroll anchoring
      if self.layoutEngine.offset(at: index)
        < self.rootView.scrollView.contentOffset.y {

        self.rootView.scrollView.contentOffset.y += delta
      }

      self.rootView.setContentHeight(
        self.layoutEngine.totalHeight
      )
    }

    // Wire layout engine into scroll handler
    scrollHandler.layoutEngine = layoutEngine
  }

  // MARK: - Layout

  func rebuildLayout() {
    guard layoutEngine.count > 0 else { return }

    layoutEngine.build()
    rootView.setContentHeight(layoutEngine.totalHeight)
    scrollHandler.forceUpdate()
  }

  // MARK: - Scroll API

  func scrollToIndex(_ index: Int, animated: Bool) {
    guard index >= 0, index < layoutEngine.count else { return }

    let y = layoutEngine.offset(at: index)
    rootView.scrollView.setContentOffset(
      CGPoint(x: 0, y: y),
      animated: animated
    )
  }

  // MARK: - Props passthrough

  func setItemCount(_ count: Int) {
    layoutEngine.itemCount = count
  }

  func setEstimatedItemHeight(_ height: CGFloat) {
    layoutEngine.estimatedItemHeight = height
  }
}
