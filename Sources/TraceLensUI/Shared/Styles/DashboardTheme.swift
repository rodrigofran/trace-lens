import SwiftUI
import TraceLensCore

enum DashboardColor {
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
  var traceColor: Color {
    switch self {
    case .get:
      .green
    case .post:
      .purple
    case .put:
      .orange
    case .patch:
      .teal
    case .delete:
      .red
    case .head, .options:
      .blue
    case .other:
      .gray
    }
  }
}
