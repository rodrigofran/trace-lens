import Foundation

public struct NetworkResponse: Sendable, Codable, Equatable {
  // MARK: - Properties

  public var statusCode: Int
  public var headers: [String: String]
  public var body: BodyReference
  public var mimeType: String?
  public var expectedContentLength: Int64?
  public var capturedSize: Int
  public var receivedAt: Date

  // MARK: - Initialization

  public init(
    statusCode: Int,
    headers: [String: String] = [:],
    body: BodyReference = .none,
    mimeType: String? = nil,
    expectedContentLength: Int64? = nil,
    capturedSize: Int = 0,
    receivedAt: Date = .now
  ) {
    self.statusCode = statusCode
    self.headers = headers
    self.body = body
    self.mimeType = mimeType
    self.expectedContentLength = expectedContentLength
    self.capturedSize = capturedSize
    self.receivedAt = receivedAt
  }
}
