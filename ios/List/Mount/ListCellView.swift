import UIKit

/// Native list cell.
/// Deterministic measurement + reuse-safe.
final class ListCellView: UIView {

  private let label = UILabel()

  // MARK: - Identity

  private(set) var index: Int = -1
  private var boundIndex: Int = -1

  // MARK: - Callbacks

  var onSizeMeasured: ((CGFloat) -> Void)?

  // MARK: - Measurement state

  private var lastMeasuredSize: CGFloat = -1
  private var lastMeasureKey: CGFloat = -1
  private var scrollAxis: ScrollAxis = .vertical

  // MARK: - Init

  override init(frame: CGRect) {
    super.init(frame: frame)

    clipsToBounds = true

    label.numberOfLines = 0
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 16)

    addSubview(label)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Axis

  func setScrollAxis(_ axis: ScrollAxis) {
    scrollAxis = axis
    invalidateMeasurement()
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    guard bounds.width > 0, bounds.height > 0 else { return }

    label.frame = bounds

    // 🔑 Measurement key (width-sensitive for vertical lists)
    let measureKey: CGFloat =
      scrollAxis == .horizontal ? bounds.height : bounds.width

    guard measureKey != lastMeasureKey else { return }
    lastMeasureKey = measureKey

    let measured: CGFloat
    if scrollAxis == .horizontal {
      let size = label.sizeThatFits(
        CGSize(width: .greatestFiniteMagnitude, height: bounds.height)
      )
      measured = size.width + 16
    } else {
      let size = label.sizeThatFits(
        CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
      )
      measured = size.height + 16
    }

    guard measured != lastMeasuredSize else { return }
    guard index == boundIndex else { return } // reuse safety

    lastMeasuredSize = measured
    onSizeMeasured?(measured)
  }

  // MARK: - Binding

  func bind(index: Int) {
    self.index = index
    self.boundIndex = index

    label.text = "Row \(index)"

    invalidateMeasurement()
  }

  // MARK: - Reuse

  func prepareForReuse() {
    index = -1
    boundIndex = -1

    label.text = nil
    onSizeMeasured = nil

    invalidateMeasurement()
  }

  // MARK: - Helpers

  private func invalidateMeasurement() {
    lastMeasuredSize = -1
    lastMeasureKey = -1
    setNeedsLayout()
  }
}
