import UIKit

/// Native list cell.
/// Deterministic measurement + reuse-safe.
final class ListCellView: UIView {

  private let label = UILabel()

  // MARK: - Identity

  private(set) var index: Int = -1
  private var boundIndex: Int = -1

  // MARK: - Style

  private var itemStyle: ItemStyle?

  // MARK: - Sticky Header

  var isStickyHeader: Bool = false

  func applyStickyOffset(_ yOffset: CGFloat?) {
    guard isStickyHeader else { return }

    if let yOffset {
      transform = CGAffineTransform(
        translationX: 0,
        y: yOffset - frame.minY
      )
      layer.zPosition = 1
    } else {
      transform = .identity
      layer.zPosition = 0
    }
  }

  // MARK: - Color Helpers

  private func decodeARGB(_ value: Double) -> UIColor {
    let argb = UInt32(value)

    let a = CGFloat((argb >> 24) & 0xFF) / 255.0
    let r = CGFloat((argb >> 16) & 0xFF) / 255.0
    let g = CGFloat((argb >> 8) & 0xFF) / 255.0
    let b = CGFloat(argb & 0xFF) / 255.0

    return UIColor(red: r, green: g, blue: b, alpha: a)
  }

  // MARK: - Callbacks

  var onSizeMeasured: ((CGFloat) -> Void)?

  // MARK: - Measurement State

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

  // MARK: - Style Application

  func applyStyle(_ style: ItemStyle?) {
    itemStyle = style

    guard let style else {
      backgroundColor = nil
      layer.cornerRadius = 0
      layer.borderWidth = 0
      layer.borderColor = nil
      invalidateMeasurement()
      return
    }

    // Background color
    if let variant = style.backgroundColor {
      switch variant {
      case .first:
        backgroundColor = nil
      case .second(let value):
        backgroundColor = decodeARGB(value)
      }
    } else {
      backgroundColor = nil
    }

    // Border color
    if let variant = style.borderColor {
      switch variant {
      case .first:
        layer.borderColor = nil
      case .second(let value):
        layer.borderColor = decodeARGB(value).cgColor
      }
    } else {
      layer.borderColor = nil
    }

    layer.cornerRadius = CGFloat(style.borderRadius ?? 0)
    layer.borderWidth = CGFloat(style.borderWidth ?? 0)

    invalidateMeasurement()
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    guard bounds.width > 0, bounds.height > 0 else { return }

    let horizontalPadding: CGFloat = {
      if let style = itemStyle, let value = style.paddingHorizontal {
        return CGFloat(value)
      }
      return 0
    }()

    let verticalPadding: CGFloat = {
      if let style = itemStyle, let value = style.paddingVertical {
        return CGFloat(value)
      }
      return 0
    }()

    label.frame = bounds.insetBy(
      dx: horizontalPadding,
      dy: verticalPadding
    )

    // 🔑 Measurement key (width-sensitive for vertical lists)
    let measureKey: CGFloat =
      scrollAxis == .horizontal ? bounds.height : bounds.width

    guard measureKey != lastMeasureKey else { return }
    lastMeasureKey = measureKey

    let measured: CGFloat
    if scrollAxis == .horizontal {
      let size = label.sizeThatFits(
        CGSize(
          width: .greatestFiniteMagnitude,
          height: bounds.height - verticalPadding * 2
        )
      )
      measured = size.width + horizontalPadding * 2
    } else {
      let size = label.sizeThatFits(
        CGSize(
          width: bounds.width - horizontalPadding * 2,
          height: .greatestFiniteMagnitude
        )
      )
      measured = size.height + verticalPadding * 2
    }

    guard measured != lastMeasuredSize else { return }
    guard index == boundIndex else { return }

    lastMeasuredSize = measured
    onSizeMeasured?(measured)
  }

  // MARK: - Binding

//  func bind(index: Int) {
//    self.index = index
//    self.boundIndex = index
//    label.text = "Row \(index)"
//    invalidateMeasurement()
//  }
  // MARK: - Binding

  func bind(index: Int, textPrefix: String?) {
    self.index = index
    self.boundIndex = index

    if let prefix = textPrefix {
      label.text = "\(prefix) \(index)"
    } else {
      label.text = nil
    }

    invalidateMeasurement()
  }


  // MARK: - Reuse

  func prepareForReuse() {
    index = -1
    boundIndex = -1

    label.text = nil
    onSizeMeasured = nil
    isStickyHeader = false
    itemStyle = nil

    applyStickyOffset(nil)
    invalidateMeasurement()
  }

  // MARK: - Helpers

  private func invalidateMeasurement() {
    lastMeasuredSize = -1
    lastMeasureKey = -1
    setNeedsLayout()
  }
}
