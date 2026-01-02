import UIKit

/// Root scroll container for the native list.
final class ListRootView: UIView, UIScrollViewDelegate {

  let scrollView = UIScrollView()
  private let contentView = UIView()

  var onScroll: ((CGFloat, CGFloat) -> Void)?
  var onLayoutReady: (() -> Void)?
  var onCellHeightChange: ((Int, CGFloat) -> Void)?

  private var visibleCells: [Int: ListCellView] = [:]
  private let reusePool = ListReusePool()
  private var didLayoutOnce = false
  private var scrollAxis: ScrollAxis = .vertical

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

  func setScrollAxis(_ axis: ScrollAxis) {
    scrollAxis = axis
    scrollView.alwaysBounceVertical = axis == .vertical
    scrollView.alwaysBounceHorizontal = axis == .horizontal
  }

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

  func mountCells(start: Int, end: Int, layout: ListLayoutEngine) {
    for (index, cell) in visibleCells where index < start || index > end {
      cell.removeFromSuperview()
      reusePool.recycle(cell)
      visibleCells.removeValue(forKey: index)
    }

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
          ? CGRect(x: offset, y: 0, width: size, height: bounds.height)
          : CGRect(x: 0, y: offset, width: bounds.width, height: size)

      contentView.addSubview(cell)
      visibleCells[index] = cell
    }
  }

  /// 🔥 REQUIRED FIX
  func relayoutVisibleCells(from startIndex: Int, layout: ListLayoutEngine) {
    for (index, cell) in visibleCells where index >= startIndex {
      let offset = layout.offset(at: index)
      let size = layout.height(at: index)

      cell.frame =
        scrollAxis == .horizontal
          ? CGRect(x: offset, y: 0, width: size, height: bounds.height)
          : CGRect(x: 0, y: offset, width: bounds.width, height: size)
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollAxis == .horizontal {
      onScroll?(scrollView.contentOffset.x, scrollView.bounds.width)
    } else {
      onScroll?(scrollView.contentOffset.y, scrollView.bounds.height)
    }
  }
}
