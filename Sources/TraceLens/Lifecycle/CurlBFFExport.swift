import Foundation
import TraceLensCore
import TraceLensStorage

enum CurlBFFExport {
  static func export(
    transaction: NetworkTransaction,
    environment: CurlBFFEnvironment,
    bodies: TemporaryBodyStore?
  ) async throws -> URL {
    let body = await bodyData(for: transaction.request.body, bodies: bodies)
    let command = try CurlExporter.bffCommand(
      for: transaction,
      bodyData: body,
      environment: environment
    )

    return try ExportFileWriter.writeText(
      command + "\n",
      named: "tracelens-bff-curl-\(transaction.id.uuidString)-\(ExportFileWriter.timestamp()).sh"
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
