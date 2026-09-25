import SwiftUI
import TraceLensCore

struct RequestDetail: View {
  // MARK: - Properties

  let transaction: NetworkTransaction
  let policy: SensitiveDataPolicy
  let onExport: (NetworkTransaction, TraceLensExportFormat) async throws -> URL

  @State private var selectedTab = RequestDetailTab.overview
  @State private var showingExportOptions = false
  @State private var shareFile: TraceLensShareFile?
  @State private var toast: String?

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
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Button {
          showingExportOptions = true
        } label: {
          Label("Exportar request", systemImage: "square.and.arrow.up")
        }
      }
    }
    .sheet(item: $shareFile) { file in
      TraceLensShareSheet(file: file) {
        shareFile = nil
      }
    }
    .confirmationDialog(
      "Exportar request",
      isPresented: $showingExportOptions,
      titleVisibility: .visible
    ) {
      Button("TXT — leitura rápida") {
        exportTransaction(format: .text)
      }

      Button("JSON — debug técnico") {
        exportTransaction(format: .json)
      }
    }
    .overlay(alignment: .top) {
      if let toast {
        TraceLensToast(message: toast)
          .padding(.top, 10)
      }
    }
  }

  // MARK: - Private Methods

  private func exportTransaction(format: TraceLensExportFormat) {
    Task {
      do {
        shareFile = try await .init(url: onExport(transaction, format))
      } catch {
        showToast("Não foi possível exportar a request")
      }
    }
  }

  private func showToast(_ message: String) {
    toast = message

    Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000)

      if toast == message {
        toast = nil
      }
    }
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
