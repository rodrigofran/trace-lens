import SwiftUI
import TraceLensCore

struct RequestDetail: View {
  // MARK: - Properties

  let transaction: NetworkTransaction
  let policy: SensitiveDataPolicy
  let bffHostSuffixes: [CurlBFFEnvironment: String]
  let onExport: (NetworkTransaction, TraceLensExportFormat) async throws -> URL
  let onExportBFFCurl: (NetworkTransaction, CurlBFFDestination) async throws -> URL

  @State private var selectedTab = RequestDetailTab.overview
  @State private var showingExportOptions = false
  @State private var showingBFFCurlEditor = false
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
    .sheet(isPresented: $showingBFFCurlEditor) {
      BFFCurlExportView(
        transaction: transaction,
        hostSuffixes: bffHostSuffixes
      ) { destination in
        showingBFFCurlEditor = false
        exportBFFCurl(destination: destination)
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

      Button("CURL — BFF") {
        showingBFFCurlEditor = true
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

  private func exportBFFCurl(destination: CurlBFFDestination) {
    Task {
      do {
        shareFile = try await .init(url: onExportBFFCurl(transaction, destination))
      } catch {
        showToast(error.localizedDescription)
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

private struct BFFCurlExportView: View {
  let transaction: NetworkTransaction
  let hostSuffixes: [CurlBFFEnvironment: String]
  let onExport: (CurlBFFDestination) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var environment: CurlBFFEnvironment = .development
  @State private var host: String
  @State private var intermediatePath = ""

  init(
    transaction: NetworkTransaction,
    hostSuffixes: [CurlBFFEnvironment: String],
    onExport: @escaping (CurlBFFDestination) -> Void
  ) {
    self.transaction = transaction
    self.hostSuffixes = hostSuffixes
    self.onExport = onExport
    _host = State(initialValue: Self.host(for: transaction, environment: .development, suffixes: hostSuffixes))
  }

  var body: some View {
    NavigationView {
      Form {
        Section("Ambiente") {
          Picker("Ambiente", selection: $environment) {
            Text("DEV").tag(CurlBFFEnvironment.development)
            Text("UAT").tag(CurlBFFEnvironment.uat)
            Text("localhost").tag(CurlBFFEnvironment.localhostPort)
          }
          .onChange(of: environment) { _, value in
            host = Self.host(for: transaction, environment: value, suffixes: hostSuffixes)
          }
        }

        Section("Destino BFF") {
          TextField("Host", text: $host)
          Text("Pré-preenchido com o componente técnico e o sufixo configurado. Você pode editar antes de exportar.")
            .font(.footnote)
            .foregroundStyle(.secondary)

          TextField("Path intermediário (opcional)", text: $intermediatePath)
          Text("Caso não exista um path entre o host e o endpoint, deixe em branco.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        Section("Endpoint capturado") {
          Text(transaction.request.parsed.endpoint)
            .textSelection(.enabled)
        }
      }
      .navigationTitle("Exportar CURL — BFF")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancelar") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Exportar") {
            onExport(.init(host: host, intermediatePath: intermediatePath))
          }
        }
      }
    }
  }

  private static func host(
    for transaction: NetworkTransaction,
    environment: CurlBFFEnvironment,
    suffixes: [CurlBFFEnvironment: String]
  ) -> String {
    if environment == .localhostPort {
      let port = suffixes[environment, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
      return port.isEmpty ? "localhost" : "localhost:\(port)"
    }

    let component = transaction.request.parsed.technicalService ?? ""
    return component + (suffixes[environment] ?? "")
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
