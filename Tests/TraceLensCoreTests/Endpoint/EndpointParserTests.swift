import XCTest

@testable import TraceLensCore

final class EndpointParserTests: XCTestCase {
  func testParserUsesConfiguredServicePresentation() throws {
    let url = try XCTUnwrap(
      URL(string: "https://api.example.test/api/v2/demo/payment-service/create")
    )
    let parsed = EndpointParser(
      strategy: .serviceAfterPathPrefix("/api/v2/demo"),
      aliases: ["payment-service": "Payments"]
    )
    .parse(url)

    XCTAssertEqual(parsed.technicalService, "payment-service")
    XCTAssertEqual(parsed.displayService, "Payments")
    XCTAssertEqual(parsed.endpoint, "/create")
  }

  func testParserUsesServiceAtPathIndex() throws {
    let url = try XCTUnwrap(
      URL(string: "https://api.example.test/v2/sicredi/payments/orders")
    )
    let parsed = EndpointParser(
      strategy: .serviceAtPathIndex(2),
      aliases: ["payments": "Pagamentos"]
    )
    .parse(url)

    XCTAssertEqual(parsed.displayService, "Pagamentos")
    XCTAssertEqual(parsed.endpoint, "/orders")
  }
}
