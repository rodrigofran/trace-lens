import SwiftUI
import TraceLensCore

struct RequestHeadersView: View {
  // MARK: - Properties

  let transaction: NetworkTransaction
  let policy: SensitiveDataPolicy

  // MARK: - View

  var body: some View {
    List {
      headersSection("Headers da request", values: transaction.request.headers)
      headersSection("Headers da response", values: transaction.response?.headers ?? [:])
    }
  }

  // MARK: - Private Methods

  private func headersSection(
    _ title: String,
    values: [String: String]
  ) -> some View {
    Section(title) {
      if transaction.captureLevel != .full {
        Text("Headers não foram capturados em requests apenas com metadata.")
          .foregroundStyle(.secondary)
      } else if values.isEmpty {
        Text("Nenhum header disponível")
          .foregroundStyle(.secondary)
      } else {
        ForEach(values.keys.sorted(), id: \.self) { key in
          HeaderValueRow(
            title: key,
            value: SensitiveData.value(values[key] ?? "", key: key, policy: policy)
          )
        }
      }
    }
  }
}
