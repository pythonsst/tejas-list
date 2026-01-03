struct ListLogger {

  static func log(
    _ category: ListLogCategory,
    _ message: @autoclosure () -> String
  ) {
    #if DEBUG
    print("[TejasList][\(category)]", message())
    #endif
  }
}
