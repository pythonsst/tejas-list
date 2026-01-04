import UIKit
import QuartzCore

/// Computes visible item range from scroll position.
///
/// GUARANTEES:
/// - Frame-driven
/// - Velocity-aware
/// - Policy-controlled fast-scroll freezing
/// - Stable windowing (no oscillation)
/// - Deduped emissions
/// - Correct anchor semantics
final class ListScrollHandler {

  // MARK: - Dependencies

  weak var layout: ListLayoutEngine?

  // MARK: - Output

  var onVisibleRangeChange: ((Int, Int) -> Void)?

  // MARK: - Configuration

  var scrollAxis: ScrollAxis = .vertical

  // MARK: - Policy (JANK controlled)

  private var fastScrollPolicy: FastScrollPolicy = .normal

  func setFastScrollPolicy(_ policy: FastScrollPolicy) {
    fastScrollPolicy = policy
  }

  // MARK: - State
  
  
  private enum ScrollFreezeState {
    case active
    case frozen
  }

  private var freezeState: ScrollFreezeState = .active


  private var lastStart: Int = -1
  private var lastEnd: Int = -1

  private var lastEmittedStart: Int = -1
  private var lastEmittedEnd: Int = -1

  // True visible anchor (NOT overscanned start)
  private var lastFirstVisible: Int = -1

  private var currentOverscan: Int = 6
  private(set) var isFastScrolling: Bool = false

  private let velocityTracker = ScrollVelocityTracker()
  private var lastVelocity: CGFloat = 0

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

    // 1. Velocity tracking
    let signedVelocity = velocityTracker.velocity(currentOffset: scrollOffset)
    lastVelocity = signedVelocity
    let absVelocity = abs(signedVelocity)

    let rawFastScroll = absVelocity > 1200

    // Policy-controlled freeze decision
    let shouldFreeze = FastScrollRules.shouldFreeze(
      isFastScrolling: rawFastScroll,
      policy: fastScrollPolicy
    )

    let newState: ScrollFreezeState = shouldFreeze ? .frozen : .active

    if newState != freezeState {
      freezeState = newState
      ListDebugLog.info(
        "Scroll freeze → \(freezeState) (velocity=\(Int(absVelocity)))"
      )
    }

    isFastScrolling = shouldFreeze


    // 2. Overscan control
    let targetOverscan: Int
    switch absVelocity {
    case 3000...: targetOverscan = 1
    case 1500..<3000: targetOverscan = 2
    case 800..<1500: targetOverscan = 4
    default: targetOverscan = 6
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

    // 3. True visible window
    let firstVisible = BinarySearch.firstVisibleIndex(
      scrollOffset: scrollOffset,
      offsets: layout.offsets
    )

    let lastVisible = BinarySearch.lastVisibleIndex(
      scrollOffset: scrollOffset,
      viewportSize: viewportSize,
      offsets: layout.offsets
    )

    lastFirstVisible = firstVisible

    // 4. Predictive overscan
    let prediction = ScrollRangePredictor.predictOverscan(
      velocity: signedVelocity,
      viewportSize: viewportSize,
      itemCount: layout.count,
      baseOverscan: overscan
    )

    let nextStart = max(firstVisible - overscan - prediction.leading, 0)
    let nextEnd = min(lastVisible + overscan + prediction.trailing, layout.count - 1)

    // 5. Stability rules
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

    // 6. Commit window
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
    lastFirstVisible >= 0 ? lastFirstVisible : nil
  }

  var velocity: CGFloat {
    lastVelocity
  }

  // MARK: - Reset

  func reset() {
    lastStart = -1
    lastEnd = -1
    lastEmittedStart = -1
    lastEmittedEnd = -1
    lastFirstVisible = -1
    currentOverscan = 6
    isFastScrolling = false
    lastVelocity = 0
    freezeState = .active   // ✅ ADD THIS
    velocityTracker.reset()
  }
}
