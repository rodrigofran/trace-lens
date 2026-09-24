import Foundation

public struct TraceLensSession: Sendable, Codable {
  // MARK: - Properties

  public let id: UUID
  public let startedAt: Date

  // MARK: - Initialization

  public init(id: UUID = UUID(), startedAt: Date = .now) {
    self.id = id
    self.startedAt = startedAt
  }
}
