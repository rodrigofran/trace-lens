import Foundation

public struct NetworkRequest: Sendable, Codable, Equatable {
  // MARK: - Properties

  public let url: URL
  public let method: HTTPMethod
  public let parsed: ParsedEndpoint
  public let startedAt: Date
  public var headers: [String: String]
  public var body: BodyReference
  public var estimatedSize: Int?

  // MARK: - Initialization

  public init(
    url: URL,
    method: HTTPMethod,
    parsed: ParsedEndpoint,
    startedAt: Date = .now,
    headers: [String: String] = [:],
    body: BodyReference = .none,
    estimatedSize: Int? = nil
  ) {
    self.url = url
    self.method = method
    self.parsed = parsed
    self.startedAt = startedAt
    self.headers = headers
    self.body = body
    self.estimatedSize = estimatedSize
  }
}
