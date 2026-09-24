import TraceLensCore
import TraceLensStorage
import XCTest

@testable import TraceLensCapture

final class CaptureTests: XCTestCase {
  func testInstrumentationPreservesClassesAndRejectsMarker() throws {
    let configuration = URLSessionConfiguration.ephemeral
    let instrumented = URLSessionInstrumentation.instrument(configuration)
    XCTAssertTrue((instrumented.protocolClasses ?? []).contains { $0 == TraceLensURLProtocol.self })
    let url = try XCTUnwrap(URL(string: "https://api.example.test/a"))
    let request = URLRequest(url: url)
    XCTAssertTrue(TraceLensURLProtocol.canInit(with: request))
    let marked = NSMutableURLRequest(url: url)
    URLProtocol.setProperty(true, forKey: "com.tracelens.handled", in: marked)
    XCTAssertFalse(TraceLensURLProtocol.canInit(with: marked as URLRequest))
  }

  func testPassiveObservationCapturesWithoutInstrumentingSession() async throws {
    let configuration = TraceLensConfiguration(defaultCapture: .full)
    let store = SessionStore(configuration: configuration)
    let bodies = try TemporaryBodyStore(limits: configuration.sessionLimits)
    let runtime = CaptureRuntime.shared
    await runtime.start(configuration: configuration, store: store, bodies: bodies)
    defer {
      Task {
        await runtime.stop()
        await bodies.clear()
      }
    }

    let url = try XCTUnwrap(URL(string: "https://api.example.test/orders"))
    let request = URLRequest(url: url)
    let transactionID = UUID()
    let didBegin = await runtime.begin(id: transactionID, request: request)
    XCTAssertTrue(didBegin)

    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
    )
    await runtime.response(response, data: Data("{\"ok\":true}".utf8), transactionID: transactionID)

    let recordedTransaction = await store.transaction(transactionID)
    let transaction = try XCTUnwrap(recordedTransaction)
    XCTAssertEqual(transaction.response?.statusCode, 200)
    XCTAssertEqual(transaction.state, .completed)
  }
}
