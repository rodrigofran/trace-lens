import SwiftUI

#if os(iOS) || os(tvOS) || os(visionOS)
  import UIKit
#endif

struct TraceLensShareFile: Identifiable {
  let id = UUID()
  let url: URL
}

struct TraceLensShareSheet: View {
  let file: TraceLensShareFile
  let onCompletion: () -> Void

  var body: some View {
    #if os(iOS) || os(tvOS) || os(visionOS)
      ActivityViewController(fileURL: file.url, onCompletion: onCompletion)
    #elseif os(macOS)
      VStack(spacing: 12) {
        Text("Arquivo de exportação criado")
          .font(.headline)
        Text(file.url.path)
          .font(.footnote.monospaced())
          .textSelection(.enabled)
        Button("Concluir", action: onCompletion)
      }
      .padding()
    #endif
  }
}

#if os(iOS) || os(tvOS) || os(visionOS)
  private struct ActivityViewController: UIViewControllerRepresentable {
    let fileURL: URL
    let onCompletion: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
      let controller = UIActivityViewController(
        activityItems: [fileURL],
        applicationActivities: nil
      )
      controller.completionWithItemsHandler = { _, _, _, _ in
        onCompletion()
      }

      return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
  }
#endif
