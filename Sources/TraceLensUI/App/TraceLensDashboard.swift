import TraceLensStorage
import SwiftUI
import TraceLensCore

public struct TraceLensDashboard: View {
  // MARK: - State

  @StateObject private var model: TraceLensViewModel

  // MARK: - Dependencies

  private let store: SessionStore?
  private let configuration: TraceLensConfiguration
  private let onClose: (() -> Void)?
  private let onConfigurationChange: (TraceLensConfiguration) -> Void
  private let onClear: () async -> Void
  private let onExport: (TraceLensExportFormat) async throws -> URL
  private let onExportTransaction: (NetworkTransaction, TraceLensExportFormat) async throws -> URL
  private let onExportBFFCurl: (NetworkTransaction, CurlBFFDestination) async throws -> URL
  private let onCopyBFFCurl: (NetworkTransaction, CurlBFFDestination) async throws -> String

  // MARK: - Initialization

  public init(
    store: SessionStore?,
    configuration: TraceLensConfiguration = .init(),
    onClose: (() -> Void)? = nil,
    onConfigurationChange: @escaping (TraceLensConfiguration) -> Void = { _ in },
    onClear: @escaping () async -> Void = {},
    onExport: @escaping (TraceLensExportFormat) async throws -> URL = { _ in
      throw TraceLensDashboardError.exportUnavailable
    },
    onExportTransaction: @escaping (NetworkTransaction, TraceLensExportFormat) async throws -> URL = {
      _, _ in throw TraceLensDashboardError.exportUnavailable
    },
    onExportBFFCurl: @escaping (NetworkTransaction, CurlBFFDestination) async throws -> URL = {
      _, _ in throw TraceLensDashboardError.exportUnavailable
    },
    onCopyBFFCurl: @escaping (NetworkTransaction, CurlBFFDestination) async throws -> String = {
      _, _ in throw TraceLensDashboardError.exportUnavailable
    }
  ) {
    self.store = store
    self.configuration = configuration
    self.onClose = onClose
    self.onConfigurationChange = onConfigurationChange
    self.onClear = onClear
    self.onExport = onExport
    self.onExportTransaction = onExportTransaction
    self.onExportBFFCurl = onExportBFFCurl
    self.onCopyBFFCurl = onCopyBFFCurl

    _model = StateObject(
      wrappedValue: TraceLensViewModel(
        store: store,
        configuration: configuration
      )
    )
  }

  // MARK: - View

  public var body: some View {
    TabView {
      RequestsScreen(
        model: model,
        policy: model.settings.sensitiveDataPolicy,
        bffHostSuffixes: configuration.bffHostSuffixes,
        onClose: onClose,
        onExportTransaction: onExportTransaction,
        onExportBFFCurl: onExportBFFCurl,
        onCopyBFFCurl: onCopyBFFCurl
      )
        .tabItem { Label("Requests", systemImage: "list.bullet.rectangle") }

      MetricsScreen(model: model, onClose: onClose)
        .tabItem {
        Label("Métricas", systemImage: "chart.bar")
      }

      ScopesScreen(model: model, store: store, onClose: onClose).tabItem {
        Label("Escopos", systemImage: "scope")
      }

      SettingsScreen(
        model: model,
        onClose: onClose,
        onConfigurationChange: onConfigurationChange,
        onClear: onClear,
        onExport: onExport
      )
      .tabItem { Label("Ajustes", systemImage: "gearshape") }
    }
    .tint(.green)
    .traceLensBackground()
  }
}

public enum TraceLensDashboardError: Error {
  case exportUnavailable
}
