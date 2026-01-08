import UIKit
import QuartzCore

/// Root scroll container for the list.
///
/// Responsibilities:
/// - Owns UIScrollView + contentView
/// - Mounts / recycles visible cells
/// - Manages prefetch pool
/// - Applies snapshot-based fast-scroll masking
///
/// Guarantees:
/// - Deterministic mount / recycle
/// - No measurement during prefetch
/// - Snapshots never mix with real cells
final class ListRootView: UIView, UIScrollViewDelegate {

  // MARK: - Views

  let scrollView = UIScrollView()
  private let contentView = UIView()
  private var scrollSignalSource: ScrollSignalSource?

  // MARK: - Snapshot cache

  private let snapshotCache = CellSnapshotCache()

  // MARK: - Coordinator callbacks

  var onScroll: ((CGFloat, CGFloat) -> Void)?
  var onLayoutReady: (() -> Void)?
  var onCellHeightChange: ((Int, CGFloat) -> Void)?

  // MARK: - State

  private var visibleCells: [Int: ListCellView] = [:]
  private var prefetchedCells: [Int: ListCellView] = [:]
  private let reusePool = ListReusePool()

  private var didLayoutOnce = false
  private var scrollAxis: ScrollAxis = .vertical

  /// Visual-only per-item style
  var itemStyle: ItemStyle?

  /// Static row label prefix (e.g. "Row")
  var itemString: String?

  /// Driven exclusively by coordinator
  var isFastScrolling: Bool = false {
    didSet {
      if oldValue && !isFastScrolling {
        clearSnapshots()
        snapshotCache.reset()
      }
    }
  }

  private let maxPrefetchCount = 40

  // MARK: - Init

  override init(frame: CGRect) {
    super.init(frame: frame)

    scrollView.delegate = self
    scrollView.contentInsetAdjustmentBehavior = .never

    scrollSignalSource =
      DisplayLinkScrollSignalSource(scrollView: scrollView)

    scrollSignalSource?.onFrame = { [weak self] offset, viewport, _ in
      self?.onScroll?(offset, viewport)
    }

    addSubview(scrollView)
    scrollView.addSubview(contentView)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Axis

  func setScrollAxis(_ axis: ScrollAxis) {
    scrollAxis = axis
    scrollView.alwaysBounceVertical = axis == .vertical
    scrollView.alwaysBounceHorizontal = axis == .horizontal
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()
    scrollView.frame = bounds

    if !didLayoutOnce, bounds.width > 0, bounds.height > 0 {
      didLayoutOnce = true
      scrollSignalSource?.start()
      onLayoutReady?()
    }
  }

  func setContentSize(_ size: CGSize) {
    contentView.frame = CGRect(origin: .zero, size: size)
    scrollView.contentSize = size
  }

  // MARK: - Prefetch (NO measurement)

  func prefetchCells(
    start: Int,
    end: Int,
    layout: ListLayoutEngine
  ) {
    guard start <= end else { return }

    for index in start...end {
      if visibleCells[index] != nil { continue }
      if prefetchedCells[index] != nil { continue }
      guard let cell = reusePool.dequeueIfAvailable() else { continue }

      cell.isHidden = true
      cell.onSizeMeasured = nil
      cell.bind(index: index, textPrefix: itemString)

      let offset = layout.offset(at: index)
      let size = layout.height(at: index)

      cell.frame =
        scrollAxis == .horizontal
          ? CGRect(x: offset, y: 0, width: size, height: bounds.height)
          : CGRect(x: 0, y: offset, width: bounds.width, height: size)

      contentView.addSubview(cell)
      prefetchedCells[index] = cell
    }

    // FIFO eviction
    while prefetchedCells.count > maxPrefetchCount {
      let (index, cell) = prefetchedCells.first!
      prefetchedCells.removeValue(forKey: index)
      cell.removeFromSuperview()
      reusePool.recycle(cell)
    }
  }

  // MARK: - Snapshot cleanup

  private func clearSnapshots() {
    snapshotCache.removeAllSnapshots(from: contentView)
  }

  // MARK: - Mount / Recycle

  func mountCells(
    start: Int,
    end: Int,
    layout: ListLayoutEngine
  ) {
    // Recycle exited cells
    for index in visibleCells.keys where index < start || index > end {
      let cell = visibleCells.removeValue(forKey: index)!

      if isFastScrolling {
        snapshotCache.snapshot(cell: cell, index: index)
      }

      cell.removeFromSuperview()
      reusePool.recycle(cell)
    }

    guard start <= end else {
      assertInvariants()
      return
    }

    for index in start...end {
      if visibleCells[index] != nil { continue }

      // Snapshot precedence during fast scroll
      if isFastScrolling,
         let snapshot = snapshotCache.snapshotView(for: index) {

        let offset = layout.offset(at: index)
        let size = layout.height(at: index)

        snapshot.frame =
          scrollAxis == .horizontal
            ? CGRect(x: offset, y: 0, width: size, height: bounds.height)
            : CGRect(x: 0, y: offset, width: bounds.width, height: size)

        contentView.addSubview(snapshot)
        continue
      }

      let cell: ListCellView

      if let prefetched = prefetchedCells.removeValue(forKey: index) {
        cell = prefetched
        cell.isHidden = false
      } else if let reused = reusePool.dequeueIfAvailable() {
        cell = reused
        cell.bind(index: index, textPrefix: itemString)
      } else {
        cell = ListCellView()
        cell.bind(index: index, textPrefix: itemString)
      }

      cell.setScrollAxis(scrollAxis)
      cell.applyStyle(itemStyle)
      cell.onSizeMeasured = { [weak self] size in
        self?.onCellHeightChange?(index, size)
      }

      let offset = layout.offset(at: index)
      let size = layout.height(at: index)

      cell.frame =
        scrollAxis == .horizontal
          ? CGRect(x: offset, y: 0, width: size, height: bounds.height)
          : CGRect(x: 0, y: offset, width: bounds.width, height: size)

      if let snapshot = snapshotCache.snapshotView(for: index) {
        contentView.insertSubview(cell, aboveSubview: snapshot)
      } else {
        contentView.addSubview(cell)
      }

      visibleCells[index] = cell
    }

    assertInvariants()
  }

  // MARK: - Sticky Header

  func applyStickyHeader(index: Int, y: CGFloat) {
    guard let cell = visibleCells[index] else { return }
    cell.applyStickyOffset(y)
  }

  func clearStickyHeader() {
    for cell in visibleCells.values {
      cell.applyStickyOffset(nil)
    }
  }

  // MARK: - Relayout

  func relayoutVisibleCells(
    from startIndex: Int,
    layout: ListLayoutEngine
  ) {
    for (index, cell) in visibleCells where index >= startIndex {
      let offset = layout.offset(at: index)
      let size = layout.height(at: index)

      cell.frame =
        scrollAxis == .horizontal
          ? CGRect(x: offset, y: 0, width: size, height: bounds.height)
          : CGRect(x: 0, y: offset, width: bounds.width, height: size)
    }
  }

  // MARK: - Scroll delegate fallback

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollAxis == .horizontal {
      onScroll?(scrollView.contentOffset.x, scrollView.bounds.width)
    } else {
      onScroll?(scrollView.contentOffset.y, scrollView.bounds.height)
    }
  }

  // MARK: - Invariants

  private func assertInvariants() {
    #if DEBUG
    assert(Set(visibleCells.keys).isDisjoint(with: prefetchedCells.keys))
    #endif
  }

  deinit {
    scrollSignalSource?.stop()
  }
}
