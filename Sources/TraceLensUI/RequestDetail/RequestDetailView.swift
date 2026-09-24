import SwiftUI
import TraceLensCore

struct RequestDetail: View {
  // MARK: - Properties

  let transaction: NetworkTransaction
  let policy: SensitiveDataPolicy

  @State private var selectedTab = RequestDetailTab.overview

  // MARK: - View

  var body: some View {
    VStack {
      Picker("Seção da request", selection: $selectedTab) {
        ForEach(RequestDetailTab.allCases) { tab in
          Text(tab.title).tag(tab)
        }
      }
      .pickerStyle(.segmented)
      .padding()

      switch selectedTab {
      case .overview:
        RequestOverviewView(transaction: transaction)
      case .headers:
        RequestHeadersView(transaction: transaction, policy: policy)
      case .body:
        RequestBodyView(transaction: transaction)
      case .metrics:
        RequestMetricsView(transaction: transaction)
      }
    }
    .navigationTitle(transaction.request.parsed.displayService ?? "Request")
  }
}

private enum RequestDetailTab: Int, CaseIterable, Identifiable {
  case overview
  case headers
  case body
  case metrics

  var id: Self {
    self
  }

  var title: String {
    switch self {
    case .overview:
      "Resumo"
    case .headers:
      "Headers"
    case .body:
      "Body"
    case .metrics:
      "Métricas"
    }
  }
}
