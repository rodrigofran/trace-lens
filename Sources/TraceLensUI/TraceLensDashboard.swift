import SwiftUI
import TraceLensCore
import TraceLensMetrics
import TraceLensStorage

#if os(iOS) || os(tvOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

@MainActor public final class TraceLensViewModel: ObservableObject {
  @Published public private(set) var snapshot: SessionSnapshot?
  @Published public var search = ""
  @Published public var method: HTTPMethod?
  @Published public var capture: CaptureLevel?
  @Published public var statusFilter: StatusFilter = .all
  @Published public var settings: TraceLensConfiguration
  private var task: Task<Void, Never>?
  public init(store: SessionStore?, configuration: TraceLensConfiguration = .init()) {
    settings = configuration
    guard let store else { return }
    task = Task { [weak self] in
      for await value in await store.updates() {
        if Task.isCancelled { break }
        self?.snapshot = value
      }
    }
  }
  deinit { task?.cancel() }
  public var transactions: [NetworkTransaction] {
    (snapshot?.transactions ?? []).filter { tx in
      let text = [
        tx.request.parsed.host, tx.request.parsed.displayService,
        tx.request.parsed.technicalService, tx.request.parsed.endpoint, tx.request.parsed.fullURL,
        tx.request.method.rawValue, tx.response.map { String($0.statusCode) },
      ].compactMap { $0 }.joined(separator: " ").lowercased()
      return (search.isEmpty || text.contains(search.lowercased()))
        && (method == nil || method == tx.request.method)
        && (capture == nil || capture == tx.captureLevel) && statusFilter.matches(tx)
    }
  }
  public var totalTransactions: Int { snapshot?.transactions.count ?? 0 }
}

public enum StatusFilter: String, CaseIterable, Identifiable {
  case all, errors
  public var id: String { rawValue }
  func matches(_ transaction: NetworkTransaction) -> Bool {
    switch self {
    case .all: return true
    case .errors:
      if transaction.error != nil { return true }
      guard let statusCode = transaction.response?.statusCode else { return false }
      return statusCode >= 400
    }
  }
}

private enum DashboardColor {
  static var groupedBackground: Color {
    #if os(iOS) || os(tvOS) || os(visionOS)
      Color(uiColor: .systemGroupedBackground)
    #elseif os(macOS)
      Color(nsColor: .windowBackgroundColor)
    #else
      Color.clear
    #endif
  }

  static var secondaryGroupedBackground: Color {
    #if os(iOS) || os(tvOS) || os(visionOS)
      Color(uiColor: .secondarySystemGroupedBackground)
    #elseif os(macOS)
      Color(nsColor: .controlBackgroundColor)
    #else
      Color.clear
    #endif
  }
}

extension HTTPMethod {
  fileprivate var traceColor: Color {
    switch self {
    case .get: .green
    case .post: .purple
    case .put: .orange
    case .patch: .teal
    case .delete: .red
    case .head, .options: .blue
    case .other: .gray
    }
  }
}

public struct TraceLensDashboard: View {
  @StateObject private var model: TraceLensViewModel
  private let store: SessionStore?
  private let configuration: TraceLensConfiguration
  private let onClose: (() -> Void)?
  private let onConfigurationChange: (TraceLensConfiguration) -> Void
  private let onClear: () async -> Void
  private let onExport: () async throws -> URL
  public init(
    store: SessionStore?, configuration: TraceLensConfiguration = .init(),
    onClose: (() -> Void)? = nil,
    onConfigurationChange: @escaping (TraceLensConfiguration) -> Void = { _ in },
    onClear: @escaping () async -> Void = {},
    onExport: @escaping () async throws -> URL = { throw TraceLensDashboardError.exportUnavailable }
  ) {
    self.store = store
    self.configuration = configuration
    self.onClose = onClose
    self.onConfigurationChange = onConfigurationChange
    self.onClear = onClear
    self.onExport = onExport
    _model = StateObject(
      wrappedValue: TraceLensViewModel(store: store, configuration: configuration))
  }
  public var body: some View {
    TabView {
      RequestsScreen(model: model, policy: model.settings.sensitiveDataPolicy, onClose: onClose)
        .tabItem { Label("Requests", systemImage: "list.bullet.rectangle") }
      MetricsScreen(model: model, onClose: onClose).tabItem {
        Label("Métricas", systemImage: "chart.bar")
      }
      ScopesScreen(model: model, store: store, onClose: onClose).tabItem {
        Label("Escopos", systemImage: "scope")
      }
      SettingsScreen(
        model: model, onClose: onClose, onConfigurationChange: onConfigurationChange,
        onClear: onClear, onExport: onExport
      ).tabItem { Label("Ajustes", systemImage: "gearshape") }
    }.tint(.green).traceLensBackground()
  }
}

public enum TraceLensDashboardError: Error { case exportUnavailable }

private struct RequestsScreen: View {
  @ObservedObject var model: TraceLensViewModel
  let policy: SensitiveDataPolicy
  let onClose: (() -> Void)?
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 12) {
          DashboardHeader(title: "TraceLens", subtitle: "\(model.totalTransactions) requests")
          RequestSearchBar(text: $model.search)
          RequestFilterBar(model: model)
          if model.transactions.isEmpty {
            EmptyRequestsView(hasFilters: hasActiveFilters)
          } else {
            ForEach(model.transactions) { tx in
              NavigationLink {
                RequestDetail(transaction: tx, policy: policy)
              } label: {
                TransactionRow(transaction: tx)
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
    }
  }
  private var hasActiveFilters: Bool {
    !model.search.isEmpty || model.method != nil || model.capture != nil
      || model.statusFilter != .all
  }
}

private struct DashboardHeader: View {
  let title: String
  let subtitle: String
  var body: some View {
    HStack(spacing: 14) {
      Image(
        systemName: title == "Métricas"
          ? "chart.bar.xaxis" : title == "Escopos" ? "scope" : "cube.transparent.fill"
      )
      .font(.title2.weight(.semibold))
      .foregroundStyle(.white)
      .frame(width: 50, height: 50)
      .background(Color.green.gradient, in: RoundedRectangle(cornerRadius: 16))
      VStack(alignment: .leading, spacing: 3) {
        Text(title).font(.title.bold())
        Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
      }
      Spacer()
      LiveBadge()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct LiveBadge: View {
  var body: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(Color.green)
        .frame(width: 8, height: 8)
      Text("Ativo")
        .font(.caption.bold())
    }
    .foregroundStyle(.green)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Color.green.opacity(0.12), in: Capsule())
  }
}

private struct RequestSearchBar: View {
  @Binding var text: String
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)
      TextField("Buscar requests, serviços ou hosts...", text: $text)
        .autocorrectionDisabled()
      if !text.isEmpty {
        Button {
          text = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
      }
    }
    .font(.subheadline)
    .padding(.horizontal, 12)
    .padding(.vertical, 11)
    .background(DashboardColor.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 10))
  }
}

private struct RequestFilterBar: View {
  @ObservedObject var model: TraceLensViewModel
  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        FilterChip(title: "Todas", isSelected: model.statusFilter == .all && model.capture == nil) {
          model.statusFilter = .all
          model.capture = nil
        }
        FilterChip(title: "Erros", isSelected: model.statusFilter == .errors) {
          model.statusFilter = model.statusFilter == .errors ? .all : .errors
        }
        FilterChip(title: "Detalhes completos", isSelected: model.capture == .full) {
          model.capture = model.capture == .full ? nil : .full
        }
        ForEach(HTTPMethod.allCases.filter { $0 != .other }, id: \.self) { method in
          MethodFilterChip(method: method, isSelected: model.method == method) {
            model.method = model.method == method ? nil : method
          }
        }
      }
      .padding(.vertical, 2)
    }
  }
}

private struct FilterChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.caption.bold())
        .foregroundStyle(isSelected ? .white : .primary)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(
          isSelected ? Color.green : DashboardColor.secondaryGroupedBackground, in: Capsule())
    }
    .buttonStyle(.plain)
  }
}

private struct MethodFilterChip: View {
  let method: HTTPMethod
  let isSelected: Bool
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Text(method.rawValue)
        .font(.caption.bold())
        .foregroundStyle(isSelected ? .white : method.traceColor)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(isSelected ? method.traceColor : method.traceColor.opacity(0.14), in: Capsule())
    }
    .buttonStyle(.plain)
  }
}

private struct EmptyRequestsView: View {
  let hasFilters: Bool
  var body: some View {
    ContentUnavailableView(
      hasFilters ? "Nenhuma request encontrada" : "Ainda não há requests",
      systemImage: hasFilters ? "line.3.horizontal.decrease.circle" : "network",
      description: Text(
        hasFilters
          ? "Ajuste a busca ou os filtros para ver o tráfego capturado."
          : "As requests de rede observadas nesta sessão aparecerão aqui.")
    )
    .padding(.top, 48)
  }
}

private struct TransactionRow: View {
  let transaction: NetworkTransaction
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      RoundedRectangle(cornerRadius: 3)
        .fill(transaction.request.method.traceColor)
        .frame(width: 5)
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(transaction.request.method.rawValue)
            .font(.caption.bold())
            .foregroundStyle(transaction.request.method.traceColor)
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(
              transaction.request.method.traceColor.opacity(0.14),
              in: RoundedRectangle(cornerRadius: 6))
          Text(transaction.request.parsed.displayService ?? transaction.request.parsed.endpoint)
            .font(.headline)
            .lineLimit(1)
          Spacer(minLength: 8)
          Text(status)
            .font(.subheadline.bold())
            .foregroundStyle(statusColor)
        }
        HStack(alignment: .top, spacing: 8) {
          VStack(alignment: .leading, spacing: 3) {
            Text(transaction.request.parsed.endpoint)
              .font(.subheadline)
              .foregroundStyle(.primary)
              .lineLimit(1)
            Text(transaction.request.parsed.fullURL)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
          Spacer(minLength: 8)
          VStack(alignment: .trailing, spacing: 3) {
            Text(duration)
            Text(transaction.captureLevel == .full ? "Completo" : "Metadata")
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(DashboardColor.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 10))
  }
  private var duration: String {
    transaction.duration.map { String(format: "%.0f ms", $0 * 1000) } ?? "Em andamento"
  }
  private var status: String {
    transaction.response.map { String($0.statusCode) }
      ?? (transaction.error == nil ? "Em andamento" : "Erro")
  }
  private var statusColor: Color {
    if transaction.error != nil { return .red }
    guard let code = transaction.response?.statusCode else { return .secondary }
    if code >= 500 { return .red }
    if code >= 400 { return .orange }
    if code >= 200 && code < 300 { return .green }
    return .secondary
  }
}

private struct RequestDetail: View {
  let transaction: NetworkTransaction
  let policy: SensitiveDataPolicy
  @State private var tab = 0
  var body: some View {
    VStack {
      Picker("Seção da request", selection: $tab) {
        Text("Resumo").tag(0)
        Text("Headers").tag(1)
        Text("Body").tag(2)
        Text("Métricas").tag(3)
      }.pickerStyle(.segmented).padding()
      if tab == 0 {
        overview
      } else if tab == 1 {
        headerList
      } else if tab == 2 {
        bodyList
      } else {
        metrics
      }
    }.navigationTitle(transaction.request.parsed.displayService ?? "Request")
  }
  private var overview: some View {
    List {
      Section("Request") {
        LabeledContent("Serviço", value: transaction.request.parsed.displayService ?? "—")
        LabeledContent("Serviço técnico", value: transaction.request.parsed.technicalService ?? "—")
        LabeledContent("Endpoint", value: transaction.request.parsed.endpoint)
        LabeledContent("Host", value: transaction.request.parsed.host)
        LabeledContent("Método", value: transaction.request.method.rawValue)
      }
      Section("URL completa") {
        Text(transaction.request.parsed.fullURL).textSelection(.enabled)
        ShareLink(item: transaction.request.parsed.fullURL) {
          Label("Copiar URL", systemImage: "doc.on.doc")
        }
      }
      Section("Status") {
        LabeledContent("Status", value: transaction.response.map { String($0.statusCode) } ?? "—")
        LabeledContent("Captura", value: transaction.captureLevel.rawValue.capitalized)
      }
    }
  }
  private var headerList: some View {
    List {
      section("Headers da request", transaction.request.headers)
      section("Headers da response", transaction.response?.headers ?? [:])
    }
  }
  private func section(_ title: String, _ values: [String: String]) -> some View {
    Section(title) {
      if transaction.captureLevel != .full {
        Text("Headers não foram capturados em requests apenas com metadata.").foregroundStyle(
          .secondary)
      } else if values.isEmpty {
        Text("Nenhum header disponível").foregroundStyle(.secondary)
      } else {
        ForEach(values.keys.sorted(), id: \.self) { key in
          LabeledContent(
            key, value: SensitiveData.value(values[key] ?? "", key: key, policy: policy))
        }
      }
    }
  }
  private var bodyList: some View {
    List {
      body("Body da request", transaction.request.body)
      body("Body da response", transaction.response?.body ?? .none)
    }
  }
  private func body(_ title: String, _ reference: BodyReference) -> some View {
    Section(title) {
      if transaction.captureLevel != .full {
        Text("Body não foi capturado. Esta request usou apenas metadata.").foregroundStyle(
          .secondary)
      } else if reference.storage == .truncated {
        Text("Body truncado. O payload original excedeu o limite de captura.").foregroundStyle(
          .secondary)
      } else if let data = reference.data, let text = String(data: data, encoding: .utf8) {
        BodyPreview(text: text)
      } else {
        Text("Body indisponível ou armazenado temporariamente.").foregroundStyle(.secondary)
      }
    }
  }
  private var metrics: some View {
    List {
      Section("Tempo") {
        timing("Total", transaction.metrics?.total ?? transaction.duration)
        timing("DNS", transaction.metrics?.dns)
        timing("TCP", transaction.metrics?.tcp)
        timing("TLS", transaction.metrics?.tls)
        timing("TTFB", transaction.metrics?.firstByte)
        timing("Download", transaction.metrics?.download)
      }
    }
  }
  private func timing(_ name: String, _ value: TimeInterval?) -> some View {
    LabeledContent(name, value: value.map { String(format: "%.0f ms", $0 * 1000) } ?? "—")
  }
}

private struct BodyPreview: View {
  private static let characterLimit = 10_000
  let text: String
  @State private var isExpanded = false

  private var isTruncated: Bool { text.count > Self.characterLimit }
  private var displayedText: String {
    isExpanded || !isTruncated ? text : String(text.prefix(Self.characterLimit))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(displayedText)
        .font(.system(.body, design: .monospaced))
        .textSelection(.enabled)

      if isTruncated {
        Button(isExpanded ? "Mostrar menos" : "Mostrar body completo") {
          isExpanded.toggle()
        }
        .buttonStyle(.bordered)
      }
    }
  }
}

private struct MetricsScreen: View {
  @ObservedObject var model: TraceLensViewModel
  let onClose: (() -> Void)?
  var body: some View {
    let values = MetricsAggregator().aggregate(model.snapshot?.transactions ?? [])
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          DashboardHeader(title: "Métricas", subtitle: "Uma visão clara desta sessão.")
          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(title: "Requests", value: String(values.totalRequests))
            MetricTile(
              title: "Duração média",
              value: values.averageDuration.map { String(format: "%.0f ms", $0 * 1000) } ?? "—")
            MetricTile(
              title: "Taxa de erros", value: String(format: "%.1f%%", values.errorRate * 100))
            MetricTile(
              title: "Detalhes completos",
              value: String(format: "%.0f%%", values.fullCaptureRatio * 100))
          }
          VStack(alignment: .leading, spacing: 9) {
            Text("Serviços mais acessados").font(.headline).foregroundStyle(.secondary)
            ForEach(values.services, id: \.service) { service in
              HStack(spacing: 12) {
                SettingsRowIcon(name: "network")
                VStack(alignment: .leading, spacing: 2) {
                  Text(service.service).font(.body.weight(.medium))
                  Text("\(service.requestCount) requests").font(.caption).foregroundStyle(
                    .secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(
                  .tertiary)
              }.padding(12).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            }
          }
        }
        .padding(20)
      }
      .traceLensBackground()
      .traceLensInlineNavigationTitle()
      .traceLensCloseToolbar(onClose)
    }
  }
}

private struct MetricTile: View {
  let title: String
  let value: String
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.title3.bold())
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
  }
}

private struct ScopesScreen: View {
  @ObservedObject var model: TraceLensViewModel
  let store: SessionStore?
  let onClose: (() -> Void)?
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          DashboardHeader(title: "Escopos", subtitle: "Escolha os serviços que serão observados.")
          ScopeSection(
            title: "Configurados", icon: "checkmark.shield",
            rules: model.snapshot?.configuredRules ?? [], store: store, removable: false)
          ScopeSection(
            title: "Sessão", icon: "clock.badge.checkmark",
            rules: model.snapshot?.sessionRules ?? [], store: store, removable: true)
          DiscoveredScopeSection(hosts: model.snapshot?.discoveredHosts ?? [], store: store)
        }.padding(20)
      }.traceLensBackground().traceLensInlineNavigationTitle().traceLensCloseToolbar(onClose)
    }
  }
}

private struct SettingsScreen: View {
  @ObservedObject var model: TraceLensViewModel
  let onClose: (() -> Void)?
  let onConfigurationChange: (TraceLensConfiguration) -> Void
  let onClear: () async -> Void
  let onExport: () async throws -> URL
  @State private var showingClearConfirmation = false
  @State private var toast: String?
  var body: some View {
    NavigationStack {
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
                  icon: "trash", title: "Limpar sessão", value: "", tint: .red, isDestructive: true)
              }
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
                SettingsValueRow(icon: "square.and.arrow.up", title: "Exportar sessão", value: "")
              }
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
      try? await Task.sleep(for: .seconds(2))
      if toast == message { toast = nil }
    }
  }
}

private struct SettingsHeader: View {
  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: "cube.transparent.fill")
        .font(.title)
        .foregroundStyle(.white)
        .frame(width: 52, height: 52)
        .background(Color.green.gradient, in: RoundedRectangle(cornerRadius: 16))
      VStack(alignment: .leading, spacing: 2) {
        Text("TraceLens").font(.title.bold())
        Text("Ajustes").font(.title3).foregroundStyle(.secondary)
      }
      Spacer()
      LiveBadge()
    }
  }
}

private struct SettingsSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content
  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      Text(title).font(.headline).foregroundStyle(.secondary)
      VStack(spacing: 0) { content }.background(
        .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
  }
}

private struct SettingsRowIcon: View {
  let name: String
  var tint: Color = .green
  var body: some View {
    Image(systemName: name).font(.title3.weight(.medium)).foregroundStyle(tint).frame(
      width: 48, height: 48
    ).background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
  }
}

private struct SettingsToggleRow: View {
  let icon: String
  let title: String
  let isOn: Binding<Bool>
  var body: some View {
    HStack(spacing: 14) {
      SettingsRowIcon(name: icon)
      Text(title).font(.body.weight(.medium))
      Spacer()
      Toggle(title, isOn: isOn).labelsHidden().tint(.green)
    }.padding(.horizontal, 14).padding(.vertical, 10).settingsDivider()
  }
}

private struct SettingsMenuRow<Content: View>: View {
  let icon: String
  let title: String
  let value: String
  @ViewBuilder let menu: Content
  var body: some View {
    HStack(spacing: 14) {
      SettingsRowIcon(name: icon)
      Text(title).font(.body.weight(.medium))
      Spacer()
      Menu {
        menu
      } label: {
        HStack(spacing: 5) {
          Text(value).foregroundStyle(.secondary)
          Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.tertiary)
        }
      }.tint(.primary)
    }.padding(.horizontal, 14).padding(.vertical, 10).settingsDivider()
  }
}

private struct SettingsValueRow: View {
  let icon: String
  let title: String
  let value: String
  var tint: Color = .green
  var isDestructive = false
  var showsDisclosure = false
  var body: some View {
    HStack(spacing: 14) {
      SettingsRowIcon(name: icon, tint: tint)
      Text(title).font(.body.weight(.medium)).foregroundStyle(isDestructive ? .red : .primary)
      Spacer()
      if !value.isEmpty { Text(value).foregroundStyle(.secondary) }
      if showsDisclosure {
        Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.tertiary)
      }
    }.padding(.horizontal, 14).padding(.vertical, 10).settingsDivider()
  }
}

private struct TraceLensToast: View {
  let message: String
  var body: some View {
    Label(message, systemImage: "checkmark.circle.fill").font(.subheadline.weight(.medium))
      .foregroundStyle(.white).padding(.horizontal, 16).padding(.vertical, 11).background(
        .green, in: Capsule()
      ).shadow(color: .black.opacity(0.16), radius: 12, y: 5).transition(
        .move(edge: .top).combined(with: .opacity))
  }
}

private struct SettingsStepperRow: View {
  let icon: String
  let title: String
  let value: Binding<Int>
  var body: some View {
    HStack(spacing: 14) {
      SettingsRowIcon(name: icon)
      Text(title).font(.body.weight(.medium))
      Spacer()
      Stepper(value: value, in: 100...10_000, step: 100) {
        Text(value.wrappedValue.formatted()).monospacedDigit()
      }.labelsHidden()
    }.padding(.horizontal, 14).padding(.vertical, 10).settingsDivider()
  }
}

private struct ScopeSection: View {
  let title: String
  let icon: String
  let rules: [ObservationRule]
  let store: SessionStore?
  let removable: Bool
  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      Text(title).font(.headline).foregroundStyle(.secondary)
      if rules.isEmpty {
        Label("Ainda não há escopos", systemImage: "circle.dashed").foregroundStyle(.secondary)
          .padding(16).frame(maxWidth: .infinity, alignment: .leading).background(
            .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
      } else {
        VStack(spacing: 0) {
          ForEach(rules) { rule in
            HStack(spacing: 12) {
              SettingsRowIcon(name: icon)
              VStack(alignment: .leading) {
                Text(rule.matcher.host ?? "Escopo personalizado").font(.body.weight(.medium))
                Text(rule.captureLevel.rawValue == "full" ? "Completo" : "Metadata").font(.caption)
                  .foregroundStyle(.secondary)
              }
              Spacer()
              if removable {
                Button(role: .destructive) {
                  Task { await store?.removeSessionRule(rule.id) }
                } label: {
                  Image(systemName: "trash")
                }
              }
            }.padding(12).settingsDivider()
          }
        }.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
      }
    }
  }
}

private struct DiscoveredScopeSection: View {
  let hosts: [String]
  let store: SessionStore?
  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      Text("Descobertos").font(.headline).foregroundStyle(.secondary)
      if hosts.isEmpty {
        Label("Serviços de novas requests aparecerão aqui", systemImage: "magnifyingglass")
          .foregroundStyle(.secondary).padding(16).frame(maxWidth: .infinity, alignment: .leading)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
      } else {
        VStack(spacing: 0) {
          ForEach(hosts, id: \.self) { host in
            HStack(spacing: 12) {
              SettingsRowIcon(name: "network")
              Text(host).font(.body.weight(.medium))
              Spacer()
              Menu {
                Button("Capturar próxima request") {
                  Task {
                    await store?.addNextRule(.host(host, capture: .full, origin: .nextRequest))
                  }
                }
                Button("Capturar nesta sessão") {
                  Task {
                    await store?.addSessionRule(.host(host, capture: .full, origin: .session))
                  }
                }
              } label: {
                Image(systemName: "ellipsis.circle").font(.title3)
              }
            }.padding(12).settingsDivider()
          }
        }.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
      }
    }
  }
}

extension View {
  @ViewBuilder
  fileprivate func traceLensInlineNavigationTitle() -> some View {
    #if os(iOS) || os(tvOS) || os(visionOS)
      navigationBarTitleDisplayMode(.inline)
    #else
      self
    #endif
  }

  @ViewBuilder
  fileprivate func traceLensCloseToolbar(_ action: (() -> Void)?) -> some View {
    #if os(macOS)
      toolbar {
        ToolbarItem {
          if let action {
            Button(action: action) { Image(systemName: "xmark").font(.body.weight(.bold)) }
              .accessibilityLabel("Fechar")
          }
        }
      }
    #else
      toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          if let action {
            Button(action: action) { Image(systemName: "xmark").font(.body.weight(.bold)) }
              .accessibilityLabel("Fechar")
          }
        }
      }
    #endif
  }

  fileprivate func traceLensBackground() -> some View {
    background {
      LinearGradient(
        colors: [
          DashboardColor.groupedBackground, Color.green.opacity(0.10),
          DashboardColor.groupedBackground,
        ], startPoint: .topLeading, endPoint: .bottomTrailing
      ).ignoresSafeArea()
    }
  }

  @ViewBuilder
  fileprivate func settingsDivider() -> some View {
    self
      .overlay(alignment: .bottom) { Divider().padding(.leading, 76) }
  }
}
