import UIKit

final class TejasListCellView: UIView {

  private let label = UILabel()
  private(set) var index: Int = -1

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .clear

    label.textAlignment = .center
    label.font = .systemFont(ofSize: 16, weight: .medium)
    addSubview(label)

    print("🟢 [CELL:init]")
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) not supported")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    label.frame = bounds
  }

  func bind(index: Int) {
    self.index = index
    label.text = "Row \(index)"

    backgroundColor =
      index % 2 == 0
        ? UIColor.systemBlue.withAlphaComponent(0.2)
        : UIColor.systemGreen.withAlphaComponent(0.2)

    print("🟢 [CELL:bind] index =", index)
  }

  func prepareForReuse() {
    print("🔴 [CELL:prepareForReuse] index =", index)
    index = -1
    label.text = nil
  }
}
