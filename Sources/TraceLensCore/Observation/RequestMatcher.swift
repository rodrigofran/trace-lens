import Foundation

public struct RequestMatcher: Sendable, Codable, Equatable {
  // MARK: - Properties

  public var scheme: String?
  public var host: String?
  public var pathPrefix: String?
  public var methods: Set<HTTPMethod>?

  // MARK: - Initialization

  public init(
    scheme: String? = nil,
    host: String? = nil,
    pathPrefix: String? = nil,
    methods: Set<HTTPMethod>? = nil
  ) {
    self.scheme = scheme?.lowercased()
    self.host = host?.lowercased()
    self.pathPrefix = pathPrefix
    self.methods = methods
  }

  // MARK: - Matching

  public func matches(_ url: URL, method: HTTPMethod) -> Bool {
    (scheme == nil || url.scheme?.lowercased() == scheme)
      && (host == nil || url.host?.lowercased() == host)
      && (pathPrefix == nil || url.path.hasPrefix(pathPrefix!))
      && (methods == nil || methods!.contains(method))
  }

  public var specificity: Int {
    (scheme == nil ? 0 : 1) + (host == nil ? 0 : 4) + (pathPrefix?.count ?? 0)
      + (methods == nil ? 0 : 2)
  }
}
