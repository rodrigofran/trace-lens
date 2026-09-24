import Foundation

public struct ObservationRuleEngine: Sendable {
  // MARK: - Initialization

  public init() {}

  // MARK: - Resolution

  public func resolve(
    url: URL,
    method: HTTPMethod,
    configured: [ObservationRule],
    session: [ObservationRule],
    next: [ObservationRule],
    defaultCapture: CaptureLevel
  ) -> ObservationRule? {
    for rules in [next, session, configured] {
      if let match = rules.filter({ $0.matcher.matches(url, method: method) }).max(by: {
        $0.matcher.specificity < $1.matcher.specificity
      }) {
        return match
      }
    }

    return nil
  }

  public func captureLevel(
    url: URL,
    method: HTTPMethod,
    configured: [ObservationRule],
    session: [ObservationRule],
    next: [ObservationRule],
    defaultCapture: CaptureLevel
  ) -> CaptureLevel {
    resolve(
      url: url,
      method: method,
      configured: configured,
      session: session,
      next: next,
      defaultCapture: defaultCapture
    )?.captureLevel ?? defaultCapture
  }
}
