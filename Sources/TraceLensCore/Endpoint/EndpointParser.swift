import Foundation

public struct EndpointParser: Sendable {
  // MARK: - Configuration

  public let strategy: EndpointPresentationStrategy
  public let aliases: [String: String]

  // MARK: - Initialization

  public init(
    strategy: EndpointPresentationStrategy = .automatic,
    aliases: [String: String] = [:]
  ) {
    self.strategy = strategy
    self.aliases = aliases
  }

  // MARK: - Parsing

  public func parse(_ url: URL) -> ParsedEndpoint {
    let host = url.host ?? ""
    let parts = url.path.split(separator: "/").map(String.init)
    var service: String?
    var endpoint = url.path.isEmpty ? "/" : url.path

    switch strategy {
    case .raw:
      break

    case .serviceAfterPathPrefix(let prefix):
      let prefixParts = prefix.split(separator: "/").map(String.init)

      if parts.starts(with: prefixParts), parts.count > prefixParts.count {
        service = parts[prefixParts.count]
        let remaining = parts.dropFirst(prefixParts.count + 1)
        endpoint = remaining.isEmpty ? "/" : "/" + remaining.joined(separator: "/")
      }

    case .serviceAtPathIndex(let index):
      if parts.indices.contains(index) {
        service = parts[index]
        let remaining = parts.dropFirst(index + 1)
        endpoint = remaining.isEmpty ? "/" : "/" + remaining.joined(separator: "/")
      }

    case .automatic:
      if parts.count >= 2 {
        service = parts.first
        endpoint = "/" + parts.dropFirst().joined(separator: "/")
      }
    }

    return .init(
      host: host,
      technicalService: service,
      displayService: service.flatMap { aliases[$0] } ?? service,
      endpoint: endpoint,
      fullURL: url.absoluteString
    )
  }
}
