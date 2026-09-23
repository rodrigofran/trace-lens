import Foundation
import TraceLensCore

public actor TemporaryBodyStore {
  // MARK: - Configuration

  private let root: URL
  private let sessionID: UUID
  private let limits: SessionLimits

  // MARK: - State

  private var storedBytes: Int64 = 0

  // MARK: - Initialization

  public init(sessionID: UUID = UUID(), limits: SessionLimits = .default) throws {
    self.sessionID = sessionID
    self.limits = limits
    root = FileManager.default.temporaryDirectory
      .appendingPathComponent("TraceLens", isDirectory: true)
      .appendingPathComponent(sessionID.uuidString, isDirectory: true)

    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("requests", isDirectory: true),
      withIntermediateDirectories: true)

    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("responses", isDirectory: true),
      withIntermediateDirectories: true)
  }

  // MARK: - Body storage

  public func store(_ data: Data, kind: String) -> BodyReference {
    guard data.count <= limits.maxBodyBytes,
      storedBytes + Int64(data.count) <= limits.maxTemporaryStorageBytes
    else {
      return .init(storage: .truncated, originalSize: data.count)
    }

    if data.count <= 64 * 1_024 {
      return .init(storage: .inline, data: data, originalSize: data.count)
    }
    let name = "\(kind)-\(UUID().uuidString).body"
    let directory = kind == "request" ? "requests" : "responses"
    let url =
      root
      .appendingPathComponent(directory, isDirectory: true)
      .appendingPathComponent(name)

    do {
      try data.write(to: url, options: .atomic)
      storedBytes += Int64(data.count)

      return .init(storage: .file, fileName: url.path, originalSize: data.count)
    } catch {
      return .init(storage: .truncated, originalSize: data.count)
    }
  }

  public func data(for reference: BodyReference) -> Data? {
    switch reference.storage {
    case .inline: return reference.data
    case .file:
      guard let path = reference.fileName else {
        return nil
      }

      return try? Data(contentsOf: URL(fileURLWithPath: path))
    default:
      return nil
    }
  }

  // MARK: - Session cleanup

  public func byteCount() -> Int64 {
    storedBytes
  }

  public func clear() {
    try? FileManager.default.removeItem(at: root)
    storedBytes = 0
  }

  public static func cleanupStaleDirectories() {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("TraceLens", isDirectory: true)
    try? FileManager.default.removeItem(at: root)
  }
}
