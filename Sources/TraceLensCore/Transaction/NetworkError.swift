import Foundation

public struct NetworkError: Sendable, Codable, Equatable {
  // MARK: - Properties

  public let domain: String
  public let code: Int
  public let message: String

  // MARK: - Initialization

  public init(_ error: Error) {
    let error = error as NSError
    domain = error.domain
    code = error.code
    message = error.localizedDescription
  }

  public init(domain: String, code: Int, message: String) {
    self.domain = domain
    self.code = code
    self.message = message
  }
}
