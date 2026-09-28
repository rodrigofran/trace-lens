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
    let scope = ScopeAddress(host)

    return .init(
      matcher: .init(host: scope.host, pathPrefix: scope.pathPrefix),
      captureLevel: capture,
      origin: origin
    )
  }
}

// MARK: - Scope Address

private struct ScopeAddress {
  // MARK: - Properties

  let host: String
  let pathPrefix: String?

  // MARK: - Initialization

  init(_ value: String) {
    let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    let urlValue = trimmedValue.contains("://")
      ? trimmedValue
      : "https://\(trimmedValue)"
    let components = URLComponents(string: urlValue)

    host = components?.host ?? trimmedValue
    pathPrefix = Self.normalizedPathPrefix(components?.path)
  }

  // MARK: - Private Methods

  private static func normalizedPathPrefix(_ path: String?) -> String? {
    guard let path, !path.isEmpty, path != "/" else {
      return nil
    }

    let prefix = path.hasPrefix("/") ? path : "/\(path)"
    let trimmedPrefix = prefix.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

    return trimmedPrefix.isEmpty ? nil : "/\(trimmedPrefix)"
  }
}
