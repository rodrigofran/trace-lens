import SwiftUI
import TraceLensUI

public struct TraceLensView: View {
  // MARK: - Properties

  private let onClose: (() -> Void)?

  // MARK: - Initialization

  /// Creates the TraceLens dashboard.
  ///
  /// - Parameter onClose: Optional action shown as a close button in the
  ///   dashboard navigation bar. Supply this when presenting the view modally.
  public init(onClose: (() -> Void)? = nil) {
    self.onClose = onClose
  }

  // MARK: - View

  public var body: some View {
    TraceLensDashboard(
      store: TraceLens.presentation.store,
      configuration: TraceLens.presentation.configuration,
      onClose: onClose,
      onConfigurationChange: TraceLens.updateConfiguration,
      onClear: TraceLens.clearSession,
      onExport: TraceLens.exportSession,
      onExportTransaction: TraceLens.exportTransaction
    )
  }
}
