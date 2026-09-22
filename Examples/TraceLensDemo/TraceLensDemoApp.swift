import SwiftUI
import TraceLens

@main
struct TraceLensDemoApp: App {
  init() {
    TraceLens.start(
      configuration: .init(
        defaultCapture: .metadata,
        configuredScopes: [.host("httpbin.org", capture: .full)],
        endpointPresentation: .serviceAfterPathPrefix("/anything"),
        serviceAliases: ["payments-demo": "Demo de pagamentos"],
        sensitiveDataPolicy: .redacted
      ))
  }
  var body: some Scene { WindowGroup { DemoHome() } }
}

private struct DemoHome: View {
  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        Button("Executar GET") { run("https://httpbin.org/get") }
        Button("Executar POST") { run("https://httpbin.org/post", method: "POST") }
        Button("Executar 404") { run("https://httpbin.org/status/404") }
        NavigationLink("Abrir TraceLens") { TraceLensView() }
      }.navigationTitle("Demo do TraceLens")
    }
  }
  private func run(_ address: String, method: String = "GET") {
    let configuration = TraceLens.instrument(.default)
    var request = URLRequest(url: URL(string: address)!)
    request.httpMethod = method
    if method == "POST" {
      request.httpBody = Data("{\"demo\":true}".utf8)
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    URLSession(configuration: configuration).dataTask(with: request).resume()
  }
}
