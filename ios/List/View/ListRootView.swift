import UIKit

final class ListRootView: UIView, UIScrollViewDelegate {

  let scrollView = UIScrollView()
  private let contentView = UIView()

  var onScroll: ((CGFloat, CGFloat) -> Void)?
  var onLayoutReady: (() -> Void)?
  var onCellHeightChange: ((Int, CGFloat) -> Void)?

  private var visibleCells: [Int: ListCellView] = [:]
  private var reusePool: [ListCellView] = []
  private var didLayoutOnce = false

  override init(frame: CGRect) {
    super.init(frame: frame)

    scrollView.delegate = self
    scrollView.alwaysBounceVertical = true
    scrollView.contentInsetAdjustmentBehavior = .never

    addSubview(scrollView)
    scrollView.addSubview(contentView)
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    scrollView.frame = bounds

    if !didLayoutOnce && bounds.height > 0 {
      didLayoutOnce = true
      onLayoutReady?()
    }
  }

  func setContentHeight(_ height: CGFloat) {
    contentView.frame = CGRect(
      x: 0, y: 0,
      width: bounds.width,
      height: height
    )
    scrollView.contentSize = contentView.bounds.size
  }

  func mountCells(
    start: Int,
    end: Int,
    layout: ListLayoutEngine
  ) {
    for (index, cell) in visibleCells where index < start || index > end {
      cell.prepareForReuse()
      cell.removeFromSuperview()
      reusePool.append(cell)
      visibleCells.removeValue(forKey: index)
    }

    for index in start...end where visibleCells[index] == nil {
      let cell = reusePool.popLast() ?? ListCellView()
      cell.bind(index: index)

      cell.onHeightMeasured = { [weak self] h in
        self?.onCellHeightChange?(index, h)
      }

      cell.frame = CGRect(
        x: 0,
        y: layout.offset(at: index),
        width: bounds.width,
        height: layout.height(at: index)
      )

      contentView.addSubview(cell)
      visibleCells[index] = cell
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    onScroll?(
      scrollView.contentOffset.y,
      scrollView.bounds.height
    )
  }
}
