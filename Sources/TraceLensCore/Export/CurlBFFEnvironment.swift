import Foundation

/// Target environment used when exporting a request directly to its BFF.
public enum CurlBFFEnvironment: String, CaseIterable, Sendable, Identifiable {
  case development
  case uat
  case localhost

  public var id: Self { self }
}

/// Destination entered when exporting a request directly to its BFF.
///
/// `host` is intentionally the complete, editable host. The initial value shown
/// in the UI is assembled from the technical component and the configured suffix.
public struct CurlBFFDestination: Sendable, Equatable {
  public var host: String
  public var intermediatePath: String

  public init(host: String, intermediatePath: String = "") {
    self.host = host
    self.intermediatePath = intermediatePath
  }
}
