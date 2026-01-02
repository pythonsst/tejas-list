import Foundation

/// Tracks mount/recycle pressure.
struct MountStats {
  private(set) var mounted: Int = 0
  private(set) var recycled: Int = 0
  private(set) var peakMounted: Int = 0

  mutating func didMount() {
    mounted += 1
    peakMounted = max(peakMounted, mounted)
  }

  mutating func didRecycle() {
    recycled += 1
    mounted = max(0, mounted - 1)
  }

  mutating func reset() {
    mounted = 0
    recycled = 0
    peakMounted = 0
  }
}
