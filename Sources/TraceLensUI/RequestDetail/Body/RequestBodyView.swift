import SwiftUI
import TraceLensCore

struct RequestBodyView: View {
  // MARK: - Properties

  let transaction: NetworkTransaction

  // MARK: - View

  var body: some View {
    List {
      bodySection(
        "Body da request",
        reference: transaction.request.body,
        contentType: contentType(in: transaction.request.headers)
      )
      bodySection(
        "Body da response",
        reference: transaction.response?.body ?? .none,
        contentType: transaction.response?.mimeType
          ?? contentType(in: transaction.response?.headers ?? [:])
      )
    }
  }

  // MARK: - Private Methods

  private func bodySection(
    _ title: String,
    reference: BodyReference,
    contentType: String?
  ) -> some View {
    Section(title) {
      if transaction.captureLevel != .full {
        Text("Body não foi capturado. Esta request usou apenas metadata.")
          .foregroundStyle(.secondary)
      } else if reference.storage == .truncated {
        Text("Body truncado. O payload original excedeu o limite de captura.")
          .foregroundStyle(.secondary)
      } else if let data = reference.data,
        let text = String(data: data, encoding: .utf8)
      {
        BodyPreview(text: BodyFormatter.format(data: data, fallback: text, contentType: contentType))
      } else {
        Text("Body indisponível ou armazenado temporariamente.")
          .foregroundStyle(.secondary)
      }
    }
  }

  private func contentType(in headers: [String: String]) -> String? {
    headers.first { key, _ in
      key.caseInsensitiveCompare("Content-Type") == .orderedSame
    }?.value
  }
}
