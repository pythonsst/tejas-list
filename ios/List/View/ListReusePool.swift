import UIKit

/// Reuse pool for native list cells.
/// Guarantees bounded memory and clean reuse.
final class ListReusePool {

  private var pool: [ListCellView] = []
  private let maxPoolSize = 32

  func dequeue() -> ListCellView {
    pool.popLast() ?? ListCellView()
  }

  func recycle(_ cell: ListCellView) {
    cell.prepareForReuse()

    guard pool.count < maxPoolSize else { return }
    pool.append(cell)
  }
}
