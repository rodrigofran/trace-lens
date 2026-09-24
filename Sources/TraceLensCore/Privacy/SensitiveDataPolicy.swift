import Foundation

public enum SensitiveDataPolicy: String, Codable, Sendable {
  case visible
  case redacted
}
