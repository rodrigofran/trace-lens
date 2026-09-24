@preconcurrency import Foundation

public enum URLSessionInstrumentation {
  // MARK: - Public API

  public static func instrument(_ configuration: URLSessionConfiguration) -> URLSessionConfiguration {
    let copy = configuration.copy() as! URLSessionConfiguration

    guard copy.identifier == nil else {
      return copy
    }

    var classes = copy.protocolClasses ?? []

    if !classes.contains(where: { $0 == TraceLensURLProtocol.self }) {
      classes.insert(TraceLensURLProtocol.self, at: 0)
    }

    copy.protocolClasses = classes

    return copy
  }
}
