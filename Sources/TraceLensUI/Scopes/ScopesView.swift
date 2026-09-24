import SwiftUI
import TraceLensCore
import TraceLensStorage

struct ScopesScreen: View {
  @ObservedObject var model: TraceLensViewModel
  let store: SessionStore?
  let onClose: (() -> Void)?

  var body: some View {
    let configuredRules = model.snapshot?.configuredRules ?? []
    let sessionRules = model.snapshot?.sessionRules ?? []

    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          DashboardHeader(title: "Escopos", subtitle: "Escolha os serviços que serão observados.")
          ScopeSection(
            title: "Configurados", icon: "checkmark.shield",
            rules: configuredRules, store: store, removable: false)
          ScopeSection(
            title: "Sessão", icon: "clock.badge.checkmark",
            rules: sessionRules, store: store, removable: true)
          DiscoveredScopeSection(
            hosts: discoveredHosts(
              from: model.snapshot?.discoveredHosts ?? [],
              excluding: configuredRules + sessionRules
            ),
            store: store
          )
        }.padding(20)
      }.traceLensBackground().traceLensInlineNavigationTitle().traceLensCloseToolbar(onClose)
    }
    .traceLensNavigationStyle()
  }

  private func discoveredHosts(
    from hosts: [String],
    excluding rules: [ObservationRule]
  ) -> [String] {
    let configuredHosts = Set(
      rules.compactMap(\.matcher.host).map { $0.lowercased() }
    )

    return hosts.filter { !configuredHosts.contains($0.lowercased()) }
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
