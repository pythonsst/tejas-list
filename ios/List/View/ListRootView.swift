import UIKit

final class ListRootView: UIView, UIScrollViewDelegate {

  let scrollView = UIScrollView()
  private let contentView = UIView()

  /// (offset, viewportSize)
  var onScroll: ((CGFloat, CGFloat) -> Void)?
  var onLayoutReady: (() -> Void)?
  var onCellHeightChange: ((Int, CGFloat) -> Void)?

  private var visibleCells: [Int: ListCellView] = [:]
  private var reusePool: [ListCellView] = []
  private var didLayoutOnce = false

  /// Default = vertical
  private var scrollAxis: ScrollAxis = .vertical

  override init(frame: CGRect) {
    super.init(frame: frame)

    scrollView.delegate = self
    scrollView.alwaysBounceVertical = true
    scrollView.alwaysBounceHorizontal = false
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

    if axis == .horizontal {
      scrollView.alwaysBounceHorizontal = true
      scrollView.alwaysBounceVertical = false
    } else {
      scrollView.alwaysBounceVertical = true
      scrollView.alwaysBounceHorizontal = false
    }
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
    // Recycle out-of-range cells
    for (index, cell) in visibleCells where index < start || index > end {
      cell.prepareForReuse()
      cell.removeFromSuperview()
      reusePool.append(cell)
      visibleCells.removeValue(forKey: index)
    }

    // Mount missing cells
    for index in start...end where visibleCells[index] == nil {
      let cell = reusePool.popLast() ?? ListCellView()

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
    }
  }

  // MARK: - Scroll Delegate

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollAxis == .horizontal {
      onScroll?(
        scrollView.contentOffset.x,
        scrollView.bounds.width
      )
    } else {
      onScroll?(
        scrollView.contentOffset.y,
        scrollView.bounds.height
      )
    }
  }
}
