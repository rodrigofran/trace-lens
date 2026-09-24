import Foundation

public enum CaptureLevel: String, Codable, Sendable, CaseIterable {
  case none
  case metadata
  case full
}
