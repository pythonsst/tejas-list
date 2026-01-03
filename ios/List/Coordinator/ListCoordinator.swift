import UIKit

final class ListCoordinator {

  // MARK: - Public

  let rootView = ListRootView()
  var onVisibleRangeChange: ((Int, Int) -> Void)?

  // MARK: - Core

  private let layoutEngine = ListLayoutEngine()
  private let scrollHandler = ListScrollHandler()
  private let measurementBatcher = MeasurementBatcher()
  private let runloopBatcher = RunloopBatcher()

  // MARK: - State

  private var scrollAxis: ScrollAxis = .vertical
  private var needsLayoutBuild = true
  private var isApplyingMeasurement = false

  // MARK: - Init

  init() {
    scrollHandler.layout = layoutEngine

    // Layout ready
    rootView.onLayoutReady = { [weak self] in
      self?.rebuildLayoutAndMount()
    }

    // Frame-synchronous scroll input
    rootView.onScroll = { [weak self] offset, viewport in
      self?.handleScroll(offset: offset, viewport: viewport)
    }

    // Visible range updates (already deduped in ScrollHandler)
    scrollHandler.onVisibleRangeChange = { [weak self] start, end in
      guard let self else { return }
      ListDebugLog.debug("Visible range committed: \(start)–\(end)")

      ListInvariants.assertRange(
        start: start,
        end: end,
        count: self.layoutEngine.count
      )

      let prefetchOverscan = 6

      let prefetchStart = max(0, start - prefetchOverscan)
      let prefetchEnd = min(self.layoutEngine.count - 1, end + prefetchOverscan)

      // Prefetch first (non-visible)
      self.rootView.prefetchCells(
        start: prefetchStart,
        end: prefetchEnd,
        layout: self.layoutEngine
      )

      // Mount visible range
      self.rootView.mountCells(
        start: start,
        end: end,
        layout: self.layoutEngine
      )

      self.onVisibleRangeChange?(start, end)
    }

    // Height measurement (record only, no mutation)
    rootView.onCellHeightChange = { [weak self] index, height in
      self?.measurementBatcher.record(index: index, height: height)
    }

    // Batched mutation — ONLY mutation point
    measurementBatcher.onFlush = { [weak self] batch in
      guard let self, !batch.isEmpty else { return }
      self.scrollHandler.handleScroll(
          scrollOffset: self.scrollAxis == .horizontal
            ? self.rootView.scrollView.contentOffset.x
            : self.rootView.scrollView.contentOffset.y,
          viewportSize: self.scrollAxis == .horizontal
            ? self.rootView.bounds.width
            : self.rootView.bounds.height
        )

      // 🔒 Hard freeze during fast scroll
      if self.scrollHandler.isFastScrolling {
        return
      }

      ListInvariants.assertMainThread()

      // Prevent re-entrancy
      guard !self.isApplyingMeasurement else { return }
      self.isApplyingMeasurement = true

      // Anchor to first visible index
      let anchorIndex =
        self.scrollHandler.firstVisibleIndex
          ?? batch.keys.min()
          ?? 0

      let oldAnchorOffset = self.layoutEngine.offset(at: anchorIndex)

      // Apply height updates
      for (index, height) in batch {
        self.layoutEngine.markHeightDirty(at: index, height: height)
      }

      self.layoutEngine.commit()

      let newAnchorOffset = self.layoutEngine.offset(at: anchorIndex)
      let anchorDelta = newAnchorOffset - oldAnchorOffset

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

      // Scroll anchoring
      if anchorDelta != 0 {
        if self.scrollAxis == .horizontal {
          self.rootView.scrollView.contentOffset.x += anchorDelta
        } else {
          self.rootView.scrollView.contentOffset.y += anchorDelta
        }
      }

      // Relayout visible cells only
      self.rootView.relayoutVisibleCells(
        from: anchorIndex,
        layout: self.layoutEngine
      )

      // Re-evaluate scroll window ONCE per runloop
      self.runloopBatcher.schedule { [weak self] in
        guard let self else { return }

        self.scrollHandler.handleScroll(
          scrollOffset: self.scrollAxis == .horizontal
            ? self.rootView.scrollView.contentOffset.x
            : self.rootView.scrollView.contentOffset.y,
          viewportSize: self.scrollAxis == .horizontal
            ? self.rootView.bounds.width
            : self.rootView.bounds.height
        )
      }

      self.isApplyingMeasurement = false
    }
  }

  // MARK: - Scroll Entry Point

  func handleScroll(
    offset: CGFloat,
    viewport: CGFloat
  ) {
    ThreadHopTracker.assertMainThread("scroll signal")

    scrollHandler.handleScroll(
      scrollOffset: offset,
      viewportSize: viewport
    )
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
    
    ListDebugLog.info(
       "Building layout (items=\(layoutEngine.itemCount), estimatedHeight=\(layoutEngine.estimatedItemHeight))"
     )

    needsLayoutBuild = false
    layoutEngine.build()
    
    ListDebugLog.info(
       "Layout built (totalSize=\(layoutEngine.totalHeight))"
     )

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
    scrollHandler.handleScroll(
      scrollOffset: scrollAxis == .horizontal
        ? rootView.scrollView.contentOffset.x
        : rootView.scrollView.contentOffset.y,
      viewportSize: scrollAxis == .horizontal
        ? rootView.bounds.width
        : rootView.bounds.height
    )
  }
}
