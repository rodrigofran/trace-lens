import XCTest

@testable import TraceLensCore

final class ObservationRuleEngineTests: XCTestCase {
  func testNextRequestRuleHasPriority() throws {
    let url = try XCTUnwrap(
      URL(string: "https://api.example.test/api/v2/demo/payment-service/create")
    )
    let engine = ObservationRuleEngine()
    let configured = ObservationRule.host("api.example.test", capture: .full)
    let next = ObservationRule.host("api.example.test", capture: .none, origin: .nextRequest)

    XCTAssertEqual(
      engine.captureLevel(
        url: url,
        method: .post,
        configured: [configured],
        session: [],
        next: [next],
        defaultCapture: .metadata
      ),
      .none
    )
  }
}
