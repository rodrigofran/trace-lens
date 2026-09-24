@preconcurrency import Foundation

#if os(iOS)
  import UIKit
#endif

/// UIKit-friendly entry point for presenting the TraceLens dashboard.
///
/// Call `TraceLens.shared.show()` from an existing debug menu or shake handler.
/// The presenter resolves the active application window and presents its own
/// `UIHostingController`, so the host does not need to use SwiftUI.
public final class TraceLensPresenter: @unchecked Sendable {
  // MARK: - Initialization

  public init() {}

  // MARK: - Presentation

  public func show() {
    #if os(iOS)
      DispatchQueue.main.async {
        TraceLensUIKitPresenter.shared.show()
      }
    #endif
  }

  public func hide() {
    #if os(iOS)
      DispatchQueue.main.async {
        TraceLensUIKitPresenter.shared.hide()
      }
    #endif
  }

  #if os(iOS)
    /// Presents TraceLens from an explicit UIKit controller when one is already available.
    public func show(from viewController: UIViewController) {
      DispatchQueue.main.async {
        TraceLensUIKitPresenter.shared.show(from: viewController)
      }
    }
  #endif
}
