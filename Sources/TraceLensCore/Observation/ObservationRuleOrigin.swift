import Foundation

public enum ObservationRuleOrigin: String, Codable, Sendable {
  case configured
  case session
  case nextRequest
}
