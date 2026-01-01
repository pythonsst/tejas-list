import UIKit

final class ListReusePool {

  private var pool: [ListCellView] = []

  func dequeue() -> ListCellView {
    pool.popLast() ?? ListCellView()
  }

  func recycle(_ cell: ListCellView) {
    pool.append(cell)
  }
}
