import UIKit

/**
 * ListCoordinator
 *
 * Orchestrates:
 * - Layout building (prefix sums)
 * - Scroll → visible range calculation
 * - Root view → mounting & recycling
 *
 * 🚫 No Nitro
 * 🚫 No UIKit math
 * 🚫 Deterministic first mount
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

    // Wire layout engine into scroll handler
    scrollHandler.layout = layoutEngine

    // 1️⃣ Layout ready (bounds are valid)
    rootView.onLayoutReady = { [weak self] in
      self?.rebuildLayoutAndMount()
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

      // Anchor scroll position
      if self.layoutEngine.offset(at: index)
        < self.rootView.scrollView.contentOffset.y {

        self.rootView.scrollView.contentOffset.y += delta
      }

      self.rootView.setContentHeight(
        self.layoutEngine.totalHeight
      )

      // Force range recalculation
      self.scrollHandler.reset()
    }
  }

  // MARK: - Layout (CRITICAL PATH)

   func rebuildLayoutAndMount() {
    guard
      layoutEngine.itemCount > 0,
      layoutEngine.estimatedItemHeight > 0,
      rootView.bounds.height > 0
    else { return }

    // 1️⃣ Build prefix sums
    layoutEngine.build()

    // 2️⃣ Set scrollable content size
    rootView.setContentHeight(layoutEngine.totalHeight)

    // 3️⃣ Reset scroll handler state
    scrollHandler.reset()

    // 4️⃣ 🔥 FORCE INITIAL VISIBLE RANGE
    scrollHandler.handleScroll(
      offsetY: rootView.scrollView.contentOffset.y,
      viewportHeight: rootView.bounds.height
    )
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
