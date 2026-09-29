import Foundation

/// Target environment used when exporting a request directly to its BFF.
public enum CurlBFFEnvironment: String, CaseIterable, Sendable, Identifiable {
  case development
  case uat
  case localhost

  public var id: Self { self }
}
