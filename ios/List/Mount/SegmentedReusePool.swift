import UIKit

final class SegmentedReusePool {

  private var pools: [CellSizeClass: [ListCellView]] = [
    .small: [],
    .medium: [],
    .large: []
  ]

  func dequeue(for size: CGFloat) -> ListCellView? {
    let cls = CellSizeClass.classify(size: size)
    return pools[cls]?.popLast()
  }

  func recycle(_ cell: ListCellView, size: CGFloat) {
    let cls = CellSizeClass.classify(size: size)
    pools[cls, default: []].append(cell)
  }

  func reset() {
    pools.removeAll()
  }
}
