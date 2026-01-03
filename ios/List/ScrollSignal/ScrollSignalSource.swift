import CoreGraphics

/// A source that emits scroll information once per frame.
/// This is the foundation of a zero-lag scroll pipeline.
protocol ScrollSignalSource: AnyObject {

  /// Called every frame with:
  /// - offset: current scroll offset
  /// - viewport: visible size
  /// - timestamp: frame timestamp
  var onFrame: ((CGFloat, CGFloat, CFTimeInterval) -> Void)? { get set }

  /// Start emitting frames
  func start()

  /// Stop emitting frames
  func stop()
}
