import SwiftUI

struct TraceLensLoadingView: View {
  // MARK: - Properties

  let onClose: () -> Void

  // MARK: - View

  var body: some View {
    NavigationView {
      ZStack {
        Color.black.opacity(0.035)
          .ignoresSafeArea()

        VStack(spacing: 16) {
          Image(systemName: "cube.transparent.fill")
            .font(.system(size: 38, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 76, height: 76)
            .background(.green, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

          Text("TraceLens")
            .font(.title.bold())

          ProgressView()
            .tint(.green)

          Text("Carregando sessão...")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .toolbar {
        closeToolbarItem
      }
    }
    .loadingNavigationStyle()
  }

  // MARK: - Toolbar

  @ToolbarContentBuilder
  private var closeToolbarItem: some ToolbarContent {
    #if os(macOS)
      ToolbarItem {
        closeButton
      }
    #else
      ToolbarItem(placement: .navigationBarTrailing) {
        closeButton
      }
    #endif
  }

  private var closeButton: some View {
    Button(action: onClose) {
      Image(systemName: "xmark")
        .font(.body.weight(.bold))
    }
    .accessibilityLabel("Fechar")
  }
}

// MARK: - Navigation Style

private extension View {
  @ViewBuilder
  func loadingNavigationStyle() -> some View {
    #if os(iOS) || os(tvOS) || os(visionOS)
      navigationViewStyle(.stack)
    #else
      self
    #endif
  }
}
