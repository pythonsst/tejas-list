import UIKit
import QuartzCore

/// Computes visible item range from scroll position.
///
/// PHASE-1 GUARANTEES:
/// - Frame-driven
/// - Direction-aware predictive windowing
/// - No oscillation during fast scroll
/// - No mount storms
/// - Bounded overscan
/// - Emits range ONLY on real change
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
    // 1. Direction-aware velocity
    // ─────────────────────────────────────

    let signedVelocity = velocityTracker.velocity(currentOffset: scrollOffset)
    let absVelocity = abs(signedVelocity)

    isFastScrolling = absVelocity > 1200

    // ─────────────────────────────────────
    // 2. Base overscan (velocity-driven)
    // ─────────────────────────────────────

    let targetOverscan: Int
    switch absVelocity {
    case 3000...:
      targetOverscan = 1
    case 1500..<3000:
      targetOverscan = 2
    case 800..<1500:
      targetOverscan = 4
    default:
      targetOverscan = 6
    }

    if !isFastScrolling {
      if targetOverscan < currentOverscan {
        currentOverscan = targetOverscan
      } else if targetOverscan > currentOverscan {
        currentOverscan += 1
      }
    }

    currentOverscan = min(currentOverscan, 8)
    let overscan = currentOverscan

    // ─────────────────────────────────────
    // 3. Visible window (prefix sums)
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

    // ─────────────────────────────────────
    // 4. Predictive windowing (direction-aware)
    // ─────────────────────────────────────

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
    // 5. Window stability rules
    // ─────────────────────────────────────

    if lastStart != -1 {
      if isFastScrolling {
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
    // 6. Commit window (deduped)
    // ─────────────────────────────────────

    lastStart = nextStart
    lastEnd = nextEnd

    if nextStart != lastEmittedStart || nextEnd != lastEmittedEnd {
      lastEmittedStart = nextStart
      lastEmittedEnd = nextEnd
      onVisibleRangeChange?(nextStart, nextEnd)
    }
  }

  // MARK: - Public read-only state

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
