import Foundation

public struct BodyReference: Sendable, Codable, Equatable {
  public enum Storage: String, Codable, Sendable {
    case none
    case inline
    case file
    case truncated
  }

  // MARK: - Properties

  public let storage: Storage
  public let data: Data?
  public let fileName: String?
  public let originalSize: Int?

  // MARK: - Initialization

  public init(
    storage: Storage = .none,
    data: Data? = nil,
    fileName: String? = nil,
    originalSize: Int? = nil
  ) {
    self.storage = storage
    self.data = data
    self.fileName = fileName
    self.originalSize = originalSize
  }

  public static let none = BodyReference()
}
