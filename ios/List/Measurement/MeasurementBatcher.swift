import UIKit

final class MeasurementBatcher {

  private var pending: [Int: CGFloat] = [:]
  private var isScheduled = false

  var onFlush: (([Int: CGFloat]) -> Void)?

  func record(index: Int, height: CGFloat) {
    pending[index] = height

    guard !isScheduled else { return }
    isScheduled = true

    DispatchQueue.main.async { [weak self] in
      self?.flush()
    }
  }

  private func flush() {
    guard !pending.isEmpty else {
      isScheduled = false
      return
    }

    let batch = pending
    pending.removeAll()
    isScheduled = false

    onFlush?(batch)
  }
}
