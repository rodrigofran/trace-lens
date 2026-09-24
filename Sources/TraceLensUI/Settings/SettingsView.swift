import SwiftUI
import TraceLensCore

struct SettingsScreen: View {
  @ObservedObject var model: TraceLensViewModel
  let onClose: (() -> Void)?
  let onConfigurationChange: (TraceLensConfiguration) -> Void
  let onClear: () async -> Void
  let onExport: () async throws -> URL
  @State private var showingClearConfirmation = false
  @State private var toast: String?
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          SettingsHeader()
          SettingsSection(title: "Captura") {
            if controls.defaultCapture {
              SettingsMenuRow(icon: "doc.text", title: "Captura padrão", value: captureName) {
                Button("Metadata") { setDefaultCapture(.metadata) }
                Button("Detalhes completos") { setDefaultCapture(.full) }
                Button("Desativada") { setDefaultCapture(.none) }
              }
            }
            if controls.networkCapture {
              SettingsToggleRow(
                icon: "point.3.connected.trianglepath.dotted", title: "Capturar tráfego de rede",
                isOn: binding(\.captureNetworkTraffic))
            }
            if controls.taskMetrics {
              SettingsToggleRow(
                icon: "gauge.with.dots.needle.50percent", title: "Capturar métricas de task",
                isOn: binding(\.captureTaskMetrics))
            }
          }
          SettingsSection(title: "Privacidade") {
            if controls.sensitiveDataPolicy {
              SettingsMenuRow(
                icon: "checkmark.shield", title: "Política de dados sensíveis",
                value: model.settings.sensitiveDataPolicy == .redacted ? "Mascarados" : "Visíveis"
              ) {
                Button("Mascarados") { setSensitiveDataPolicy(.redacted) }
                Button("Visíveis") { setSensitiveDataPolicy(.visible) }
              }
            }
            if controls.maskTokens {
              SettingsToggleRow(icon: "lock", title: "Mascarar tokens", isOn: maskTokensBinding)
            }
          }
          SettingsSection(title: "Sessão") {
            SettingsValueRow(
              icon: "cylinder", title: "Transações",
              value: String(model.snapshot?.transactions.count ?? 0))
            if controls.transactionLimit {
              SettingsStepperRow(
                icon: "tray.full", title: "Limite de transações", value: limitBinding)
            }
            SettingsValueRow(
              icon: "externaldrive", title: "Armazenamento temporário", value: storageText)
            if controls.clearSession {
              Button {
                showingClearConfirmation = true
              } label: {
                SettingsValueRow(
                  icon: "trash",
                  title: "Limpar sessão",
                  value: "",
                  tint: .red,
                  isDestructive: true,
                  showsDivider: false
                )
              }
              .buttonStyle(.plain)
            }
            if controls.exportSession {
              Button {
                Task {
                  do {
                    _ = try await onExport()
                    showToast("Sessão exportada")
                  } catch { showToast("Não foi possível exportar a sessão") }
                }
              } label: {
                SettingsValueRow(
                  icon: "square.and.arrow.up",
                  title: "Exportar sessão",
                  value: "",
                  showsDivider: false
                )
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(20)
      }
      .traceLensBackground()
      .traceLensInlineNavigationTitle()
      .traceLensCloseToolbar(onClose)
      .confirmationDialog(
        "Limpar esta sessão do TraceLens?", isPresented: $showingClearConfirmation,
        titleVisibility: .visible
      ) {
        Button("Limpar sessão", role: .destructive) {
          Task {
            await onClear()
            showToast("Sessão limpa")
          }
        }
      }
      .overlay(alignment: .top) {
        if let toast { TraceLensToast(message: toast).padding(.top, 10) }
      }
    }
    .traceLensNavigationStyle()
  }

  private var captureName: String { model.settings.defaultCapture.rawValue.capitalized }
  private var controls: TraceLensSettingsControls { model.settings.settingsControls }
  private var storageText: String {
    let bytes =
      model.snapshot?.transactions.reduce(0) {
        $0 + ($1.request.estimatedSize ?? 0) + ($1.response?.capturedSize ?? 0)
      } ?? 0
    return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
  }
  private func binding<T>(_ keyPath: WritableKeyPath<TraceLensConfiguration, T>) -> Binding<T> {
    Binding(
      get: { model.settings[keyPath: keyPath] },
      set: { value in
        model.settings[keyPath: keyPath] = value
        onConfigurationChange(model.settings)
      })
  }
  private func setDefaultCapture(_ value: CaptureLevel) {
    model.settings.defaultCapture = value
    onConfigurationChange(model.settings)
  }
  private func setSensitiveDataPolicy(_ value: SensitiveDataPolicy) {
    model.settings.sensitiveDataPolicy = value
    onConfigurationChange(model.settings)
  }
  private var maskTokensBinding: Binding<Bool> {
    Binding(
      get: { model.settings.sensitiveDataPolicy == .redacted },
      set: { enabled in
        model.settings.sensitiveDataPolicy = enabled ? .redacted : .visible
        onConfigurationChange(model.settings)
      })
  }
  private var limitBinding: Binding<Int> {
    Binding(
      get: { model.settings.sessionLimits.maxTransactions },
      set: { value in
        model.settings.sessionLimits.maxTransactions = value
        onConfigurationChange(model.settings)
      })
  }
  private func showToast(_ message: String) {
    toast = message
    Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      if toast == message { toast = nil }
    }
  }
}
