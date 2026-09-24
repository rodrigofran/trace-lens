import Foundation

public struct NetworkMetrics: Sendable, Codable, Equatable {
  // MARK: - Properties

  public var total: TimeInterval?
  public var dns: TimeInterval?
  public var tcp: TimeInterval?
  public var tls: TimeInterval?
  public var upload: TimeInterval?
  public var firstByte: TimeInterval?
  public var download: TimeInterval?
  public var protocolName: String?
  public var reusedConnection: Bool?
  public var redirectCount: Int

  // MARK: - Initialization

  public init(
    total: TimeInterval? = nil,
    dns: TimeInterval? = nil,
    tcp: TimeInterval? = nil,
    tls: TimeInterval? = nil,
    upload: TimeInterval? = nil,
    firstByte: TimeInterval? = nil,
    download: TimeInterval? = nil,
    protocolName: String? = nil,
    reusedConnection: Bool? = nil,
    redirectCount: Int = 0
  ) {
    self.total = total
    self.dns = dns
    self.tcp = tcp
    self.tls = tls
    self.upload = upload
    self.firstByte = firstByte
    self.download = download
    self.protocolName = protocolName
    self.reusedConnection = reusedConnection
    self.redirectCount = redirectCount
  }
}
