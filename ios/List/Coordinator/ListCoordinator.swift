import UIKit

/// Native orchestrator for layout, scrolling, and mounting.
/// Guarantees:
/// - No layout mutation while cells are mounted
/// - Batched height measurement
/// - Atomic prefix-sum commits
final class ListCoordinator {

  // MARK: - Public

  let rootView = ListRootView()
  var onVisibleRangeChange: ((Int, Int) -> Void)?

  // MARK: - Core components

  private let layoutEngine = ListLayoutEngine()
  private let scrollHandler = ListScrollHandler()
  private let measurementBatcher = MeasurementBatcher()
  private let relayoutAnimator = RelayoutAnimator()

  // MARK: - State

  private var scrollAxis: ScrollAxis = .vertical
  private var needsLayoutBuild = true

  // MARK: - Init

  init() {
    scrollHandler.layout = layoutEngine

    // Layout ready (first mount)
    rootView.onLayoutReady = { [weak self] in
      self?.rebuildLayoutAndMount()
    }

    // Scroll updates
    rootView.onScroll = { [weak self] offset, viewport in
      self?.scrollHandler.handleScroll(
        scrollOffset: offset,
        viewportSize: viewport
      )
    }

    // Visible range updates
    scrollHandler.onVisibleRangeChange = { [weak self] start, end in
      guard let self else { return }

      self.rootView.mountCells(
        start: start,
        end: end,
        layout: self.layoutEngine
      )

      self.onVisibleRangeChange?(start, end)
    }

    // 🔹 HEIGHT MEASUREMENT (record only — NO layout mutation)
    rootView.onCellHeightChange = { [weak self] index, height in
      guard let self else { return }
      self.measurementBatcher.record(index: index, height: height)
    }

    // 🔹 BATCH FLUSH (ONLY place layout is mutated)
    measurementBatcher.onFlush = { [weak self] batch in
      guard let self else { return }

      // Compute max local delta for animation gating
      let maxDelta: CGFloat = batch.map {
        abs($0.value - self.layoutEngine.height(at: $0.key))
      }.max() ?? 0

      // Mark dirty (NO offsets mutation)
      batch.forEach {
        self.layoutEngine.markHeightDirty(
          at: $0.key,
          height: $0.value
        )
      }

      // Atomic commit
      self.layoutEngine.commit()

      // Update content size
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

      // Animated relayout from earliest changed index
      let startIndex = batch.keys.min() ?? 0
      self.rootView.relayoutVisibleCellsAnimated(
        from: startIndex,
        layout: self.layoutEngine,
        animator: self.relayoutAnimator,
        delta: maxDelta
      )

      // Re-evaluate visible range
      let scrollOffset =
        self.scrollAxis == .horizontal
          ? self.rootView.scrollView.contentOffset.x
          : self.rootView.scrollView.contentOffset.y

      let viewport =
        self.scrollAxis == .horizontal
          ? self.rootView.bounds.width
          : self.rootView.bounds.height

      self.scrollHandler.reset()
      self.scrollHandler.handleScroll(
        scrollOffset: scrollOffset,
        viewportSize: viewport
      )
    }
  }

  // MARK: - Public API

  func setScrollDirection(_ direction: ScrollDirection?) {
    scrollAxis = direction == .horizontal ? .horizontal : .vertical
    scrollHandler.scrollAxis = scrollAxis
    rootView.setScrollAxis(scrollAxis)

    needsLayoutBuild = true
    reload()
  }

  func reload() {
    scrollHandler.reset()
    rebuildLayoutAndMount()
  }

  func setItemCount(_ count: Int) {
    layoutEngine.itemCount = count
    needsLayoutBuild = true
  }

  func setEstimatedItemHeight(_ height: CGFloat) {
    layoutEngine.estimatedItemHeight = height
    needsLayoutBuild = true
  }

  func scrollToIndex(_ index: Int, animated: Bool) {
    guard index >= 0, index < layoutEngine.count else { return }

    let offset = layoutEngine.offset(at: index)
    rootView.scrollView.setContentOffset(
      scrollAxis == .horizontal
        ? CGPoint(x: offset, y: 0)
        : CGPoint(x: 0, y: offset),
      animated: animated
    )
  }

  // MARK: - Internal

  private func rebuildLayoutAndMount() {
    guard
      needsLayoutBuild,
      layoutEngine.itemCount > 0,
      layoutEngine.estimatedItemHeight > 0,
      rootView.bounds.width > 0,
      rootView.bounds.height > 0
    else { return }

    needsLayoutBuild = false

    // Initial estimated layout
    layoutEngine.build()

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

    let scrollOffset =
      scrollAxis == .horizontal
        ? rootView.scrollView.contentOffset.x
        : rootView.scrollView.contentOffset.y

    let viewport =
      scrollAxis == .horizontal
        ? rootView.bounds.width
        : rootView.bounds.height

    scrollHandler.handleScroll(
      scrollOffset: scrollOffset,
      viewportSize: viewport
    )
  }
}
