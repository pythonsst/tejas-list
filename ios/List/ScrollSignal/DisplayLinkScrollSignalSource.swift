import UIKit
import QuartzCore

/// Frame-synchronous scroll signal source using CADisplayLink.
final class DisplayLinkScrollSignalSource: ScrollSignalSource {

  private weak var scrollView: UIScrollView?
  private var displayLink: CADisplayLink?

  var onFrame: ((CGFloat, CGFloat, CFTimeInterval) -> Void)?

  init(scrollView: UIScrollView) {
    self.scrollView = scrollView
  }

  func start() {
    stop()
    let link = CADisplayLink(
      target: self,
      selector: #selector(onTick)
    )
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  func stop() {
    displayLink?.invalidate()
    displayLink = nil
  }

  @objc private func onTick(_ link: CADisplayLink) {
    guard let scrollView else { return }

    let offset = scrollView.contentOffset.y
    let viewport = scrollView.bounds.height

    onFrame?(offset, viewport, link.timestamp)
    
  }
}
