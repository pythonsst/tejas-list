import UIKit

/// Deterministic mount / recycle manager.
/// HARD guarantees:
/// - Two-phase update (recycle → mount)
/// - No mutation during iteration
/// - Bounded allocation
final class ListMountManager {

  private var visibleCells: [Int: ListCellView] = [:]
  private let reusePool = ListReusePool()

  private var totalAllocated = 0
  private var peakMounted = 0

  func updateVisibleRange(
    start: Int,
    end: Int,
    layout: ListLayoutEngine,
    container: UIView,
    axis: ScrollAxis,
    onSizeMeasured: @escaping (Int, CGFloat) -> Void
  ) {
    guard start <= end else { return }

    // -------------------------
    // PHASE 1: RECYCLE (snapshot keys)
    // -------------------------
    let currentIndices = Array(visibleCells.keys)

    for index in currentIndices {
      if index < start || index > end {
        let cell = visibleCells[index]!
        cell.removeFromSuperview()
        reusePool.recycle(cell)
        visibleCells.removeValue(forKey: index)
      }
    }

    // -------------------------
    // PHASE 2: MOUNT
    // -------------------------
    for index in start...end {
      if visibleCells[index] != nil { continue }

      let cell = dequeueCell()
      cell.setScrollAxis(axis)
      cell.bind(index: index)

      cell.onSizeMeasured = { height in
        onSizeMeasured(index, height)
      }

      let offset = layout.offset(at: index)
      let size = layout.height(at: index)

      cell.frame =
        axis == .horizontal
          ? CGRect(
              x: offset,
              y: 0,
              width: size,
              height: container.bounds.height
            )
          : CGRect(
              x: 0,
              y: offset,
              width: container.bounds.width,
              height: size
            )

      container.addSubview(cell)
      visibleCells[index] = cell
    }

    peakMounted = max(peakMounted, visibleCells.count)
  }

  // -------------------------
  // Allocation control
  // -------------------------
  private func dequeueCell() -> ListCellView {
    if let cell = reusePool.dequeueIfAvailable() {
      return cell
    }

    // 🔒 Hard guard — allocation allowed only during warm-up
    totalAllocated += 1
    assert(
      totalAllocated <= peakMounted + 4,
      "❌ Cell allocation leak detected"
    )

    return ListCellView()
  }

  func reset() {
    for (_, cell) in visibleCells {
      cell.removeFromSuperview()
      reusePool.recycle(cell)
    }
    visibleCells.removeAll()
  }
}
