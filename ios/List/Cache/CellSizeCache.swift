import CoreGraphics

/// Caches measured cell sizes.
final class CellSizeCache {

  private var cache: [Int: CGFloat] = [:]

  func size(for index: Int) -> CGFloat? {
    cache[index]
  }

  func store(size: CGFloat, for index: Int) {
    cache[index] = size
  }

  func reset() {
    cache.removeAll()
  }
}
