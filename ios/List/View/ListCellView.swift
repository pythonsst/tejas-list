import UIKit

final class ListCellView: UIView {

  private let label = UILabel()
  private(set) var index: Int = -1

  /// Called when the measured size changes
  var onSizeMeasured: ((CGFloat) -> Void)?

  /// Cache last reported size to avoid layout thrashing
  private var lastMeasuredSize: CGFloat = -1

  /// Current scroll axis (default = vertical)
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
    lastMeasuredSize = -1 // force re-measure
    setNeedsLayout()
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    label.frame = bounds

    let measuredSize: CGFloat =
      scrollAxis == .horizontal
        ? label.intrinsicContentSize.width + 16
        : label.intrinsicContentSize.height + 16

    guard measuredSize != lastMeasuredSize else { return }

    lastMeasuredSize = measuredSize
    onSizeMeasured?(measuredSize)
  }

  // MARK: - Binding

  func bind(index: Int) {
    self.index = index
    label.text = "Row \(index)"

    backgroundColor =
      index.isMultiple(of: 2)
        ? .systemBlue.withAlphaComponent(0.15)
        : .systemGreen.withAlphaComponent(0.15)
  }

  // MARK: - Reuse

  func prepareForReuse() {
    index = -1
    label.text = nil
    onSizeMeasured = nil
    lastMeasuredSize = -1
  }
}
