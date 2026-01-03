import UIKit
import QuartzCore

/// Computes visible item range from scroll position.
///
/// PHASE-1 GUARANTEES:
/// - Frame-driven (DisplayLink-compatible)
/// - No oscillation during fast scroll
/// - No mount storms
/// - Bounded overscan growth
/// - Emits range ONLY on real change
/// - ZERO logging in hot path
final class ListScrollHandler {

  // MARK: - Dependencies

  weak var layout: ListLayoutEngine?

  // MARK: - Output

  var onVisibleRangeChange: ((Int, Int) -> Void)?

  // MARK: - Configuration

  var scrollAxis: ScrollAxis = .vertical

  // MARK: - State (authoritative)

  private var lastStart: Int = -1
  private var lastEnd: Int = -1

  private var lastEmittedStart: Int = -1
  private var lastEmittedEnd: Int = -1

  private var currentOverscan: Int = 6
  private(set) var isFastScrolling: Bool = false

  private let velocityTracker = ScrollVelocityTracker()

  // MARK: - Scroll handling (HOT PATH)

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

    let signedVelocity = velocityTracker.velocity(currentOffset: scrollOffset)
    let absVelocity = abs(signedVelocity)

    isFastScrolling = absVelocity > 1200


    // ─────────────────────────────────────
    // 2. Target overscan (velocity-driven)
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

    // Overscan convergence (never explode)
    if !isFastScrolling {
      if targetOverscan < currentOverscan {
        currentOverscan = targetOverscan
      } else if targetOverscan > currentOverscan {
        currentOverscan += 1
      }
    }

    // HARD CAP — prevents mount explosion
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

    let prediction = ScrollRangePredictor.predictOverscan(
      velocity: signedVelocity,
      viewportSize: viewportSize,
      itemCount: layout.count,
      baseOverscan: overscan
    )

    let nextStart = max(
      firstVisible - overscan - prediction.leading,
      0
    )

    let nextEnd = min(
      lastVisible + overscan + prediction.trailing,
      layout.count - 1
    )


    // ─────────────────────────────────────
    // 4. Window stability rules
    // ─────────────────────────────────────

    if lastStart != -1 {
      if isFastScrolling {
        // Hard freeze unless window fully exits
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

    // Emit ONLY if range actually changed
    if nextStart != lastEmittedStart || nextEnd != lastEmittedEnd {
      lastEmittedStart = nextStart
      lastEmittedEnd = nextEnd

      onVisibleRangeChange?(nextStart, nextEnd)
    }
  }

  // MARK: - Public read-only state

  /// First visible index from the last committed window.
  /// Used for scroll anchoring.
  var firstVisibleIndex: Int? {
    lastStart >= 0 ? lastStart : nil
  }

  // MARK: - Reset

  func reset() {
    lastStart = -1
    lastEnd = -1
    lastEmittedStart = -1
    lastEmittedEnd = -1
    currentOverscan = 6
    isFastScrolling = false
    velocityTracker.reset()
  }
}
