import UIKit

/// Root scroll container for the native list.
/// Owns mounting, recycling, and frame application.
final class ListRootView: UIView, UIScrollViewDelegate {

  let scrollView = UIScrollView()
  private let contentView = UIView()

  // MARK: - Callbacks

  var onScroll: ((CGFloat, CGFloat) -> Void)?
  var onLayoutReady: (() -> Void)?
  var onCellHeightChange: ((Int, CGFloat) -> Void)?

  // MARK: - State

  private var visibleCells: [Int: ListCellView] = [:]
  private let reusePool = ListReusePool()
  private var didLayoutOnce = false
  private var scrollAxis: ScrollAxis = .vertical

  // MARK: - Instrumentation 🔥

  private var mountedCount: Int = 0
  private var peakMountedCount: Int = 0
  private var totalMounted: Int = 0
  private var totalRecycled: Int = 0

  // MARK: - Init

  override init(frame: CGRect) {
    super.init(frame: frame)

    scrollView.delegate = self
    scrollView.contentInsetAdjustmentBehavior = .never

    addSubview(scrollView)
    scrollView.addSubview(contentView)
  }

  required init?(coder: NSCoder) {
    fatalError()
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

    if !didLayoutOnce && bounds.width > 0 && bounds.height > 0 {
      didLayoutOnce = true
      onLayoutReady?()
    }
  }

  func setContentSize(_ size: CGSize) {
    contentView.frame = CGRect(origin: .zero, size: size)
    scrollView.contentSize = size
  }

  // MARK: - Cell Mounting

  func mountCells(
    start: Int,
    end: Int,
    layout: ListLayoutEngine
  ) {
    // 1️⃣ Collect out-of-range indices
    let indicesToRecycle = visibleCells.keys.filter {
      $0 < start || $0 > end
    }

    for index in indicesToRecycle {
      guard let cell = visibleCells[index] else { continue }

      cell.removeFromSuperview()
      reusePool.recycle(cell)
      visibleCells.removeValue(forKey: index)

      // 📉 Instrument recycle
      mountedCount = max(0, mountedCount - 1)
      totalRecycled += 1
    }

    // 2️⃣ Mount missing cells
    for index in start...end where visibleCells[index] == nil {
      let cell = reusePool.dequeue()

      cell.setScrollAxis(scrollAxis)
      cell.bind(index: index)

      cell.onSizeMeasured = { [weak self] size in
        self?.onCellHeightChange?(index, size)
      }

      let offset = layout.offset(at: index)
      let size = layout.height(at: index)

      cell.frame =
        scrollAxis == .horizontal
          ? CGRect(
              x: offset,
              y: 0,
              width: size,
              height: bounds.height
            )
          : CGRect(
              x: 0,
              y: offset,
              width: bounds.width,
              height: size
            )

      contentView.addSubview(cell)
      visibleCells[index] = cell

      // 📈 Instrument mount
      mountedCount += 1
      totalMounted += 1
      if mountedCount > peakMountedCount {
        peakMountedCount = mountedCount
      }

    }

    // 🔍 Log snapshot (throttled by visible range changes)
    debugPrint(
      """
      [ListRootView]
      Mounted: \(mountedCount)
      Peak: \(peakMountedCount)
      Total mounts: \(totalMounted)
      Total recycled: \(totalRecycled)
      Visible range: \(start)–\(end)
      """
    )
  }
  
  func relayoutVisibleCellsAnimated(
    from startIndex: Int,
    layout: ListLayoutEngine,
    animator: RelayoutAnimator,
    delta: CGFloat
  ) {
    let sortedIndices = visibleCells.keys
      .filter { $0 >= startIndex }
      .sorted()

    let applyFrames = {
      for index in sortedIndices {
        guard let cell = self.visibleCells[index] else { continue }
        let offset = layout.offset(at: index)
        let size = layout.height(at: index)

        cell.frame =
          self.scrollAxis == .horizontal
            ? CGRect(x: offset, y: 0, width: size, height: self.bounds.height)
            : CGRect(x: 0, y: offset, width: self.bounds.width, height: size)
      }
    }

    if animator.shouldAnimate(delta: delta) {
      animator.animate(applyFrames)
    } else {
      applyFrames()
    }
  }


  // MARK: - Relayout

  /// Re-applies frames to already-mounted cells after a layout commit.
  func relayoutVisibleCells(
    from startIndex: Int,
    layout: ListLayoutEngine
  ) {
    let sortedIndices = visibleCells.keys
      .filter { $0 >= startIndex }
      .sorted()

    for index in sortedIndices {
      guard let cell = visibleCells[index] else { continue }

      let offset = layout.offset(at: index)
      let size = layout.height(at: index)

      cell.frame =
        scrollAxis == .horizontal
          ? CGRect(
              x: offset,
              y: 0,
              width: size,
              height: bounds.height
            )
          : CGRect(
              x: 0,
              y: offset,
              width: bounds.width,
              height: size
            )
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
}
