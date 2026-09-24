import Foundation

public struct ParsedEndpoint: Sendable, Codable, Equatable {
  // MARK: - Properties

  public let host: String
  public let technicalService: String?
  public let displayService: String?
  public let endpoint: String
  public let fullURL: String

  // MARK: - Initialization

  public init(
    host: String,
    technicalService: String?,
    displayService: String?,
    endpoint: String,
    fullURL: String
  ) {
    self.host = host
    self.technicalService = technicalService
    self.displayService = displayService
    self.endpoint = endpoint
    self.fullURL = fullURL
  }
}
