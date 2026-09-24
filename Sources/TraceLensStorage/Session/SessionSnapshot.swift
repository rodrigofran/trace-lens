import Foundation
import TraceLensCore

public struct SessionSnapshot: Sendable {
  // MARK: - Properties

  public let session: TraceLensSession
  public let transactions: [NetworkTransaction]
  public let configuredRules: [ObservationRule]
  public let sessionRules: [ObservationRule]
  public let nextRules: [ObservationRule]
  public let discoveredHosts: [String]
}
