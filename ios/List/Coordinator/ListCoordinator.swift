import UIKit

/// Central orchestration layer for the list.
/// Owns layout, scroll logic, measurement, jank control, and sticky headers.
///
/// HARD GUARANTEES:
/// - Single mutation point for layout
/// - No scroll → layout feedback loops
/// - Sticky headers are pure overlay (no layout mutation)
final class ListCoordinator {

  // MARK: - Public

  let rootView = ListRootView()
  var onVisibleRangeChange: ((Int, Int) -> Void)?

  // MARK: - Core Systems

  private let layoutEngine = ListLayoutEngine()
  private let scrollHandler = ListScrollHandler()
  private let measurementBatcher = MeasurementBatcher()
  private let runloopBatcher = RunloopBatcher()

  // Phase-2 / Phase-3
  private let initialBootstrapper = InitialWindowBootstrapper()
  private let deferredRelayoutQueue = DeferredRelayoutQueue()
  private let directionTracker = ScrollDirectionTracker()
  private let windowPredictor = VisibleWindowPredictor()
  private let stickyHeaderManager = StickyHeaderManager()
  private var itemStyle: ItemStyle?
  // Static row label prefix (e.g. "Row")
  private var itemString: String?



  // Performance
  private let fpsMonitor = FPSMonitor()
  private let jankController = JankController()

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

    // FPS → Jank policy
    fpsMonitor.onFPS = { [weak self] fps in
      guard let self else { return }
      if self.jankController.update(fps: fps) {
        self.applyJankPolicy()
      }
    }
    fpsMonitor.start()
    applyJankPolicy()

    // Scroll input
    rootView.onScroll = { [weak self] offset, viewport in
      self?.handleScroll(offset: offset, viewport: viewport)
    }

    // Visible range updates
    scrollHandler.onVisibleRangeChange = { [weak self] start, end in
      guard let self else { return }

      ListInvariants.assertRange(
        start: start,
        end: end,
        count: self.layoutEngine.count
      )

      let overscan = 6
      let prefetchStart = max(0, start - overscan)
      let prefetchEnd = min(self.layoutEngine.count - 1, end + overscan)

      self.rootView.prefetchCells(
        start: prefetchStart,
        end: prefetchEnd,
        layout: self.layoutEngine
      )

      self.rootView.mountCells(
        start: start,
        end: end,
        layout: self.layoutEngine
      )

      self.onVisibleRangeChange?(start, end)

      // Predictive prefetch
      if self.scrollHandler.isFastScrolling,
         self.windowPredictor.isEnabled,
         let prediction = self.windowPredictor.predict(
           currentStart: start,
           currentEnd: end,
           itemCount: self.layoutEngine.count,
           velocity: self.scrollHandler.velocity,
           motion: self.directionTracker.motion
         ) {
        self.rootView.prefetchCells(
          start: prediction.start,
          end: prediction.end,
          layout: self.layoutEngine
        )
      }
    }

    // Measurement capture
    rootView.onCellHeightChange = { [weak self] index, height in
      self?.measurementBatcher.record(index: index, height: height)
    }

    // Measurement flush (ONLY mutation point)
    measurementBatcher.onFlush = { [weak self] batch in
      guard let self, !batch.isEmpty else { return }
      self.processMeasurementBatch(batch)
    }
  }

  // MARK: - Scroll Entry Point
  
  // MARK: - Layout Spacing

  func setRowSpacing(_ spacing: CGFloat) {
    layoutEngine.rowSpacing = spacing
    needsLayoutBuild = true
  }

  func setColumnSpacing(_ spacing: CGFloat) {
    layoutEngine.columnSpacing = spacing
    needsLayoutBuild = true
  }

  
  
  func setItemStyle(_ style: ItemStyle?) {
    self.itemStyle = style
    rootView.itemStyle = style   // ← REQUIRED
    needsLayoutBuild = true
  }
  
  func setItemString(_ value: String?) {
    itemString = value
    rootView.itemString = value
  }



  func handleScroll(offset: CGFloat, viewport: CGFloat) {
    ThreadHopTracker.assertMainThread("scroll")

    directionTracker.update(offset: offset)

    scrollHandler.handleScroll(
      scrollOffset: offset,
      viewportSize: viewport
    )

    rootView.isFastScrolling = scrollHandler.isFastScrolling

    // Sticky headers (disabled during fast scroll)
    guard
      !scrollHandler.isFastScrolling,
      let firstVisible = scrollHandler.firstVisibleIndex
    else {
      rootView.clearStickyHeader()
      return
    }

    if let sticky = stickyHeaderManager.resolveStickyHeader(
      scrollOffset: offset,
      firstVisibleIndex: firstVisible,
      layout: layoutEngine,
      sections: layoutEngine.sections
    ) {
      rootView.applyStickyHeader(
        index: sticky.index,
        y: sticky.y
      )
    } else {
      rootView.clearStickyHeader()
    }
  }

  // MARK: - Measurement Handling

  private func processMeasurementBatch(_ batch: [Int: CGFloat]) {
    scrollHandler.handleScroll(
      scrollOffset: scrollAxis == .horizontal
        ? rootView.scrollView.contentOffset.x
        : rootView.scrollView.contentOffset.y,
      viewportSize: scrollAxis == .horizontal
        ? rootView.bounds.width
        : rootView.bounds.height
    )

    rootView.isFastScrolling = scrollHandler.isFastScrolling

    if scrollHandler.isFastScrolling {
      deferredRelayoutQueue.recordDirty(from: batch.keys.min() ?? 0)
      return
    }

    ListInvariants.assertMainThread()
    guard !isApplyingMeasurement else { return }

    isApplyingMeasurement = true
    defer { isApplyingMeasurement = false }

    let anchorIndex =
      scrollHandler.firstVisibleIndex
      ?? batch.keys.min()
      ?? 0

    let oldOffset = layoutEngine.offset(at: anchorIndex)

    for (index, height) in batch {
      layoutEngine.markHeightDirty(at: index, height: height)
    }

    layoutEngine.commit()

    let newOffset = layoutEngine.offset(at: anchorIndex)
    let delta = newOffset - oldOffset

    rootView.setContentSize(
      scrollAxis == .horizontal
        ? CGSize(width: layoutEngine.totalHeight, height: rootView.bounds.height)
        : CGSize(width: rootView.bounds.width, height: layoutEngine.totalHeight)
    )

    if delta != 0 {
      if scrollAxis == .horizontal {
        rootView.scrollView.contentOffset.x += delta
      } else {
        rootView.scrollView.contentOffset.y += delta
      }
    }

    rootView.relayoutVisibleCells(
      from: anchorIndex,
      layout: layoutEngine
    )

    runloopBatcher.schedule { [weak self] in
      guard let self else { return }

      self.scrollHandler.handleScroll(
        scrollOffset: self.scrollAxis == .horizontal
          ? self.rootView.scrollView.contentOffset.x
          : self.rootView.scrollView.contentOffset.y,
        viewportSize: self.scrollAxis == .horizontal
          ? self.rootView.bounds.width
          : self.rootView.bounds.height
      )

      self.rootView.isFastScrolling = self.scrollHandler.isFastScrolling

      if !self.scrollHandler.isFastScrolling,
         let startIndex = self.deferredRelayoutQueue.consume() {
        self.layoutEngine.commit()
        self.rootView.relayoutVisibleCells(
          from: startIndex,
          layout: self.layoutEngine
        )
      }
    }
  }

  // MARK: - Jank Policy

  private func applyJankPolicy() {
    switch jankController.state {
    case .normal:
      scrollHandler.setFastScrollPolicy(.normal)
      measurementBatcher.isSuspended = false
      windowPredictor.isEnabled = true

    case .degraded:
      scrollHandler.setFastScrollPolicy(.aggressive)
      measurementBatcher.isSuspended = true
      windowPredictor.isEnabled = false
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
    directionTracker.reset()
    initialBootstrapper.reset()
    deferredRelayoutQueue.reset()
    jankController.reset()
    applyJankPolicy()
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
    layoutEngine.build()

    rootView.setContentSize(
      scrollAxis == .horizontal
        ? CGSize(width: layoutEngine.totalHeight, height: rootView.bounds.height)
        : CGSize(width: rootView.bounds.width, height: layoutEngine.totalHeight)
    )

    if let window = initialBootstrapper.bootstrapIfNeeded(
      itemCount: layoutEngine.count,
      estimatedItemHeight: layoutEngine.estimatedItemHeight,
      viewportSize: scrollAxis == .horizontal
        ? rootView.bounds.width
        : rootView.bounds.height
    ) {
      rootView.mountCells(
        start: window.start,
        end: window.end,
        layout: layoutEngine
      )
    }

    scrollHandler.handleScroll(
      scrollOffset: scrollAxis == .horizontal
        ? rootView.scrollView.contentOffset.x
        : rootView.scrollView.contentOffset.y,
      viewportSize: scrollAxis == .horizontal
        ? rootView.bounds.width
        : rootView.bounds.height
    )

    rootView.isFastScrolling = scrollHandler.isFastScrolling
  }

  deinit {
    fpsMonitor.stop()
  }
}
