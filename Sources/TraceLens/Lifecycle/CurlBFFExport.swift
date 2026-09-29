import Foundation
import TraceLensCore
import TraceLensStorage

enum CurlBFFExport {
  static func export(
    transaction: NetworkTransaction,
    destination: CurlBFFDestination,
    bodies: TemporaryBodyStore?
  ) async throws -> URL {
    let command = try await command(
      transaction: transaction,
      destination: destination,
      bodies: bodies
    )

    return try ExportFileWriter.writeText(
      command + "\n",
      named: "tracelens-bff-curl-\(transaction.id.uuidString)-\(ExportFileWriter.timestamp()).sh"
    )
  }

  static func command(
    transaction: NetworkTransaction,
    destination: CurlBFFDestination,
    bodies: TemporaryBodyStore?
  ) async throws -> String {
    let body = await bodyData(for: transaction.request.body, bodies: bodies)
    return try CurlExporter.bffCommand(
      for: transaction,
      bodyData: body,
      destination: destination
    )
  }

  private static func bodyData(
    for reference: BodyReference,
    bodies: TemporaryBodyStore?
  ) async -> Data? {
    switch reference.storage {
    case .inline:
      reference.data
    case .file:
      await bodies?.data(for: reference)
    case .none, .truncated:
      nil
    }
  }
}
