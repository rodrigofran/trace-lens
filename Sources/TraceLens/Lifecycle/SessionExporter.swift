import Foundation
import TraceLensCore
import TraceLensStorage

/// Routes export requests to the formatter that owns each output format.
enum SessionExporter {
  static func exportSession(
    snapshot: SessionSnapshot,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?,
    format: TraceLensExportFormat
  ) async throws -> URL {
    switch format {
    case .text:
      try await SessionTextExporter.export(snapshot: snapshot, configuration: configuration, bodies: bodies)
    case .json:
      try await SessionJSONExporter.export(snapshot: snapshot, configuration: configuration, bodies: bodies)
    }
  }

  static func exportTransaction(
    _ transaction: NetworkTransaction,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?,
    format: TraceLensExportFormat
  ) async throws -> URL {
    switch format {
    case .text:
      try await SessionTextExporter.export(transaction, configuration: configuration, bodies: bodies)
    case .json:
      try await SessionJSONExporter.export(transaction, configuration: configuration, bodies: bodies)
    }
  }
}
