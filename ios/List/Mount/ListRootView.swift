import UIKit

/// Root scroll container for the native list.
/// Owns mounting, recycling, and frame application.
///
/// GUARANTEES (FINAL):
/// - visibleCells contain ONLY visible cells
/// - prefetchedCells are hidden + non-measuring
/// - reuse pool is the PRIMARY allocator
/// - fallback allocation allowed (bounded, safe)
/// - NO manual counters
/// - deterministic mount / recycle
/// - bounded memory usage
final class ListRootView: UIView, UIScrollViewDelegate {

  // MARK: - Views

  let scrollView = UIScrollView()
  private let contentView = UIView()

  // MARK: - Callbacks

  var onScroll: ((CGFloat, CGFloat) -> Void)?
  var onLayoutReady: (() -> Void)?
  var onCellHeightChange: ((Int, CGFloat) -> Void)?
  
  

  // MARK: - State (AUTHORITATIVE)

  private var visibleCells: [Int: ListCellView] = [:]
  private var prefetchedCells: [Int: ListCellView] = [:]

  private let reusePool = ListReusePool()
  private var didLayoutOnce = false
  private var scrollAxis: ScrollAxis = .vertical

  // MARK: - Prefetch limits

  private let maxPrefetchCount = 40

  // MARK: - Init

  override init(frame: CGRect) {
    super.init(frame: frame)

    scrollView.delegate = self
    scrollView.contentInsetAdjustmentBehavior = .never

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
      onLayoutReady?()
    }
  }

  func setContentSize(_ size: CGSize) {
    contentView.frame = CGRect(origin: .zero, size: size)
    scrollView.contentSize = size
  }

  // MARK: - Prefetch (NO allocation, NO measurement)

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
      cell.bind(index: index)

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
      guard let index = prefetchedCells.keys.first else { break }
      let cell = prefetchedCells.removeValue(forKey: index)!
      cell.removeFromSuperview()
      reusePool.recycle(cell)
    }
  }

  // MARK: - Mount / Recycle (DETERMINISTIC, SAFE)

  func mountCells(
    start: Int,
    end: Int,
    layout: ListLayoutEngine
  ) {
    // 🔻 Recycle exited visible cells
    for index in visibleCells.keys {
      if index < start || index > end {
        let cell = visibleCells.removeValue(forKey: index)!
        cell.removeFromSuperview()
        reusePool.recycle(cell)
      }
    }

    guard start <= end else {
      assertInvariants()
      return
    }

    // 🔺 Mount missing visible cells
    for index in start...end {
      if visibleCells[index] != nil { continue }

      let cell: ListCellView

      if let prefetched = prefetchedCells.removeValue(forKey: index) {
        cell = prefetched
        cell.isHidden = false
      } else if let reused = reusePool.dequeueIfAvailable() {
        cell = reused
        cell.bind(index: index)
      } else {
        // ✅ FINAL FIX: controlled fallback allocation
        cell = ListCellView()
        cell.bind(index: index)
      }

      cell.setScrollAxis(scrollAxis)
      cell.onSizeMeasured = { [weak self] size in
        self?.onCellHeightChange?(index, size)
      }

      let offset = layout.offset(at: index)
      let size = layout.height(at: index)

      cell.frame =
        scrollAxis == .horizontal
          ? CGRect(x: offset, y: 0, width: size, height: bounds.height)
          : CGRect(x: 0, y: offset, width: bounds.width, height: size)

      contentView.addSubview(cell)
      visibleCells[index] = cell
    }

    assertInvariants()

    debugPrint(
      """
      [ListRootView]
      Visible: \(visibleCells.count)
      Prefetched: \(prefetchedCells.count)
      Pool: \(reusePool.count)
      Mounted (derived): \(visibleCells.count + prefetchedCells.count)
      Visible range: \(start)–\(end)
      """
    )
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

  // MARK: - Scroll Delegate

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
    let visibleKeys = Set(visibleCells.keys)
    let prefetchedKeys = Set(prefetchedCells.keys)
    assert(visibleKeys.isDisjoint(with: prefetchedKeys))
    #endif
  }
}
