import SwiftUI

extension View {
  @ViewBuilder
  func traceLensNavigationStyle() -> some View {
    #if os(iOS)
      navigationViewStyle(.stack)
    #else
      self
    #endif
  }

  @ViewBuilder
  func traceLensInlineNavigationTitle() -> some View {
    #if os(iOS) || os(tvOS) || os(visionOS)
      navigationBarTitleDisplayMode(.inline)
    #else
      self
    #endif
  }

  @ViewBuilder
  func traceLensCloseToolbar(_ action: (() -> Void)?) -> some View {
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
        ToolbarItem(placement: .navigationBarTrailing) {
          if let action {
            Button(action: action) { Image(systemName: "xmark").font(.body.weight(.bold)) }
              .accessibilityLabel("Fechar")
          }
        }
      }
    #endif
  }

  func traceLensBackground() -> some View {
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
  func settingsDivider(_ visible: Bool = true) -> some View {
    if visible {
      self.overlay(alignment: .bottom) { Divider().padding(.leading, 76) }
    } else {
      self
    }
  }
}
