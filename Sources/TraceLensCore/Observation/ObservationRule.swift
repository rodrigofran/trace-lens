import Foundation

public struct ObservationRule: Sendable, Codable, Equatable, Identifiable {
  // MARK: - Properties

  public let id: UUID
  public let matcher: RequestMatcher
  public let captureLevel: CaptureLevel
  public let origin: ObservationRuleOrigin

  // MARK: - Initialization

  public init(
    id: UUID = UUID(),
    matcher: RequestMatcher,
    captureLevel: CaptureLevel,
    origin: ObservationRuleOrigin = .configured
  ) {
    self.id = id
    self.matcher = matcher
    self.captureLevel = captureLevel
    self.origin = origin
  }

  // MARK: - Factory Methods

  public static func host(
    _ host: String,
    capture: CaptureLevel,
    origin: ObservationRuleOrigin = .configured
  ) -> Self {
    .init(matcher: .init(host: host), captureLevel: capture, origin: origin)
  }
}
