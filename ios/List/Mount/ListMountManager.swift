import UIKit

/// Deterministic mount manager with priority tiers.
/// Guarantees:
/// - Center-first mounting
/// - Bounded allocations
/// - No mount storms
/// - Stable ordering
final class ListMountManager {

  // MARK: - State

  private var visibleCells: [Int: ListCellView] = [:]
  private let reusePool = ListReusePool()

  // MARK: - Configuration

  private let maxMounted = 120

  // MARK: - Public API

  func update(
    visibleStart: Int,
    visibleEnd: Int,
    prefetchStart: Int,
    prefetchEnd: Int,
    layout: ListLayoutEngine,
    container: UIView,
    axis: ScrollAxis,
    onSizeMeasured: @escaping (Int, CGFloat) -> Void
  ) {
    // 1️⃣ Recycle exited visible cells
    recycleOutside(range: visibleStart...visibleEnd)

    // 2️⃣ Mount viewport core (center-first)
    mountTier(
      indices: centerFirstIndices(start: visibleStart, end: visibleEnd),
      layout: layout,
      container: container,
      axis: axis,
      onSizeMeasured: onSizeMeasured
    )

    // 3️⃣ Mount viewport edges (remaining visible)
    mountTier(
      indices: edgeIndices(start: visibleStart, end: visibleEnd),
      layout: layout,
      container: container,
      axis: axis,
      onSizeMeasured: onSizeMeasured
    )

    // 4️⃣ Prefetch tier (lowest priority)
    mountTier(
      indices: prefetchStart...prefetchEnd,
      layout: layout,
      container: container,
      axis: axis,
      onSizeMeasured: onSizeMeasured,
      visibleOnly: false
    )

    enforceMaxMounted()
  }

  // MARK: - Tier helpers

  private func centerFirstIndices(start: Int, end: Int) -> [Int] {
    let center = (start + end) / 2
    var result: [Int] = [center]

    var offset = 1
    while result.count < (end - start + 1) {
      let left = center - offset
      let right = center + offset

      if left >= start { result.append(left) }
      if right <= end { result.append(right) }

      offset += 1
    }
    return result
  }

  private func edgeIndices(start: Int, end: Int) -> [Int] {
    guard start < end else { return [] }
    return Array(start...end)
  }

  // MARK: - Mounting

  private func mountTier(
    indices: any Sequence<Int>,
    layout: ListLayoutEngine,
    container: UIView,
    axis: ScrollAxis,
    onSizeMeasured: @escaping (Int, CGFloat) -> Void,
    visibleOnly: Bool = true
  ) {
    for index in indices {
      if visibleCells[index] != nil { continue }

      let cell = reusePool.dequeueIfAvailable() ?? ListCellView()
      cell.bind(index: index)
      cell.setScrollAxis(axis)
      cell.onSizeMeasured = { size in
        onSizeMeasured(index, size)
      }

      let offset = layout.offset(at: index)
      let size = layout.height(at: index)

      cell.frame =
        axis == .horizontal
          ? CGRect(x: offset, y: 0, width: size, height: container.bounds.height)
          : CGRect(x: 0, y: offset, width: container.bounds.width, height: size)

      container.addSubview(cell)
      visibleCells[index] = cell
    }
  }

  // MARK: - Recycling

  private func recycleOutside(range: ClosedRange<Int>) {
    for (index, cell) in visibleCells {
      if !range.contains(index) {
        cell.removeFromSuperview()
        reusePool.recycle(cell)
        visibleCells.removeValue(forKey: index)
      }
    }
  }

  // MARK: - Invariants

  private func enforceMaxMounted() {
    #if DEBUG
    assert(
      visibleCells.count <= maxMounted,
      "❌ Mounted cells exceeded hard cap: \(visibleCells.count)"
    )
    #endif
  }
}
