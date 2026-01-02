import UIKit
import QuartzCore

/// Computes visible item range from scroll position.
/// READ-ONLY over layout — never mutates layout or views.
final class ListScrollHandler {

  // MARK: - Dependencies (read-only)

  weak var layout: ListLayoutEngine?

  // MARK: - Output

  /// Called when visible index range changes
  var onVisibleRangeChange: ((Int, Int) -> Void)?

  // MARK: - Configuration

  /// Current scroll axis (set by coordinator)
  var scrollAxis: ScrollAxis = .vertical

  // MARK: - Internal state

  private var lastStart: Int = -1
  private var lastEnd: Int = -1
  private var currentOverscan: Int = 6


  private let velocityTracker = ScrollVelocityTracker()

  // MARK: - Public API

  func handleScroll(
    scrollOffset: CGFloat,
    viewportSize: CGFloat
  ) {
    guard
      let layout,
      layout.count > 0,
      viewportSize > 0
    else { return }

    // 🔥 Velocity-aware overscan
    let velocity = velocityTracker.velocity(
      currentOffset: scrollOffset
    )
    
    let targetOverscan: Int
    switch velocity {
    case 3000...:
      targetOverscan = 1
    case 1500..<3000:
      targetOverscan = 2
    case 800..<1500:
      targetOverscan = 4
    default:
      targetOverscan = 6
    }

    // 🔒 Hysteresis: only shrink overscan aggressively
    if targetOverscan < currentOverscan {
      currentOverscan = targetOverscan
    } else if targetOverscan > currentOverscan + 1 {
      currentOverscan += 1
    }

    let overscan = currentOverscan


    // Compute visible window using prefix sums
    let firstVisible = BinarySearch.firstVisibleIndex(
      scrollOffset: scrollOffset,
      offsets: layout.offsets
    )

    let lastVisible = BinarySearch.lastVisibleIndex(
      scrollOffset: scrollOffset,
      viewportSize: viewportSize,
      offsets: layout.offsets
    )

    // Apply overscan and clamp
    let start = max(firstVisible - overscan, 0)
    let end = min(lastVisible + overscan, layout.count - 1)

    // No change → do nothing
    guard start != lastStart || end != lastEnd else { return }

    lastStart = start
    lastEnd = end

    onVisibleRangeChange?(start, end)
  }

  /// Must be called when layout changes (commit, rebuild)
  func reset() {
    lastStart = -1
    lastEnd = -1
    currentOverscan = 6 
    velocityTracker.reset()
  }
}
