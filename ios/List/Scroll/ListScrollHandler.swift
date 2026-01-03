import UIKit
import QuartzCore

/// Computes visible item range from scroll position.
/// HARD guarantees:
/// - Window monotonicity during fast scroll
/// - No oscillation
/// - No mount storms
/// - Bounded overscan growth
final class ListScrollHandler {

  // MARK: - Dependencies

  weak var layout: ListLayoutEngine?

  // MARK: - Output

  var onVisibleRangeChange: ((Int, Int) -> Void)?

  // MARK: - Configuration

  var scrollAxis: ScrollAxis = .vertical

  // MARK: - State

  private var lastStart: Int = -1
  private var lastEnd: Int = -1

  private var currentOverscan: Int = 6
  private(set) var isFastScrolling: Bool = false

  private let velocityTracker = ScrollVelocityTracker()

  // MARK: - Scroll handling

  func handleScroll(
    scrollOffset: CGFloat,
    viewportSize: CGFloat
  ) {
    guard
      let layout,
      layout.count > 0,
      viewportSize > 0
    else { return }

    // ─────────────────────────────────────
    // 1. Velocity classification
    // ─────────────────────────────────────

    let velocity = velocityTracker.velocity(currentOffset: scrollOffset)
    isFastScrolling = velocity > 1200

    // ─────────────────────────────────────
    // 2. Target overscan (velocity driven)
    // ─────────────────────────────────────

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

    // 🔒 Overscan convergence (NEVER explode)
    if !isFastScrolling {
      if targetOverscan < currentOverscan {
        currentOverscan = targetOverscan
      } else if targetOverscan > currentOverscan {
        currentOverscan += 1
      }
    }

    // HARD CAP (prevents your 14k mounted bug)
    currentOverscan = min(currentOverscan, 8)
    let overscan = currentOverscan

    // ─────────────────────────────────────
    // 3. Visible window via prefix sums
    // ─────────────────────────────────────

    let firstVisible = BinarySearch.firstVisibleIndex(
      scrollOffset: scrollOffset,
      offsets: layout.offsets
    )

    let lastVisible = BinarySearch.lastVisibleIndex(
      scrollOffset: scrollOffset,
      viewportSize: viewportSize,
      offsets: layout.offsets
    )

    let nextStart = max(firstVisible - overscan, 0)
    let nextEnd = min(lastVisible + overscan, layout.count - 1)

    // ─────────────────────────────────────
    // 4. Window stability rules (CRITICAL)
    // ─────────────────────────────────────

    if lastStart != -1 {
      if isFastScrolling {
        // 🔒 HARD FREEZE unless window fully exits
        if nextStart >= lastStart && nextEnd <= lastEnd {
          return
        }
      } else {
        let threshold = max(1, overscan / 2)
        if abs(nextStart - lastStart) < threshold &&
           abs(nextEnd - lastEnd) < threshold {
          return
        }
      }
    }

    // ─────────────────────────────────────
    // 5. Commit window
    // ─────────────────────────────────────

    lastStart = nextStart
    lastEnd = nextEnd

    onVisibleRangeChange?(nextStart, nextEnd)
  }

  // MARK: - Reset

  func reset() {
    lastStart = -1
    lastEnd = -1
    currentOverscan = 6
    isFastScrolling = false
    velocityTracker.reset()
  }
}

