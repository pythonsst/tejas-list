import UIKit

/// Native list cell.
/// Measures itself only when content or axis changes.
final class ListCellView: UIView {

  private let label = UILabel()
  private(set) var index: Int = -1

  var onSizeMeasured: ((CGFloat) -> Void)?

  private var lastMeasuredSize: CGFloat = -1
  private var cachedIntrinsicSize: CGSize = .zero
  private var scrollAxis: ScrollAxis = .vertical

  override init(frame: CGRect) {
    super.init(frame: frame)

    label.numberOfLines = 0
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 16)
    addSubview(label)
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  // MARK: - Axis

  func setScrollAxis(_ axis: ScrollAxis) {
    scrollAxis = axis
    lastMeasuredSize = -1
    setNeedsLayout()
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    label.frame = bounds

    let measuredSize: CGFloat =
      scrollAxis == .horizontal
        ? cachedIntrinsicSize.width + 16
        : cachedIntrinsicSize.height + 16

    guard measuredSize != lastMeasuredSize else { return }

    lastMeasuredSize = measuredSize
    onSizeMeasured?(measuredSize)
  }

  // MARK: - Binding

  func bind(index: Int) {
    self.index = index
    label.text = "Row \(index)"
    cachedIntrinsicSize = label.intrinsicContentSize
    lastMeasuredSize = -1
    setNeedsLayout()

    backgroundColor =
      index.isMultiple(of: 2)
        ? .systemBlue.withAlphaComponent(0.15)
        : .systemGreen.withAlphaComponent(0.15)
  }

  // MARK: - Reuse

  func prepareForReuse() {
    index = -1
    label.text = nil
    cachedIntrinsicSize = .zero
    onSizeMeasured = nil
    lastMeasuredSize = -1
  }
}
