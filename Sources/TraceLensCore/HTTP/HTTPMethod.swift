import Foundation

public enum HTTPMethod: String, Codable, Sendable, CaseIterable, Hashable {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case patch = "PATCH"
  case delete = "DELETE"
  case head = "HEAD"
  case options = "OPTIONS"
  case other = "OTHER"

  public init(_ value: String?) {
    self = HTTPMethod(rawValue: (value ?? "GET").uppercased()) ?? .other
  }
}
