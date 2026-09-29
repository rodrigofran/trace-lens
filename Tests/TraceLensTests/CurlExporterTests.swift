import Foundation
import XCTest
@testable import TraceLens
import TraceLensCore

final class CurlExporterTests: XCTestCase {
  func testBFFCommandUsesDevelopmentHostEndpointQueryAndBearer() throws {
    let command = try CurlExporter.bffCommand(
      for: transaction(),
      bodyData: Data("{\"amount\":100}".utf8),
      environment: .development
    )

    XCTAssertEqual(
      command,
      "curl -X POST 'https://payment-service.dev.sicredi.cloud/v1/payments?dryRun=true' -H 'Authorization: Bearer token-value' -H 'Content-Type: application/json' --data-raw '{\"amount\":100}'"
    )
  }

  func testBFFCommandUsesUATAndLocalhostDestinations() throws {
    XCTAssertTrue(try CurlExporter.bffCommand(for: transaction(), bodyData: nil, environment: .uat)
      .contains("https://payment-service.uat.sicredi.cloud/v1/payments?dryRun=true"))
    XCTAssertTrue(try CurlExporter.bffCommand(for: transaction(), bodyData: nil, environment: .localhost)
      .contains("http://localhost:8080/v1/payments?dryRun=true"))
  }

  func testBFFCommandRequiresBearerToken() throws {
    var value = transaction()
    value.request.headers = [:]
    XCTAssertThrowsError(try CurlExporter.bffCommand(for: value, bodyData: nil, environment: .development)) {
      XCTAssertEqual($0 as? CurlExporter.Error, .missingBearerToken)
    }
  }

  private func transaction() -> NetworkTransaction {
    let url = URL(string: "https://gateway.dev.sicredi.cloud/payment-service/v1/payments?dryRun=true")!
    let parsed = ParsedEndpoint(
      host: "gateway.dev.sicredi.cloud",
      technicalService: "payment-service",
      displayService: "Payments",
      endpoint: "/v1/payments",
      fullURL: url.absoluteString
    )
    return .init(
      request: .init(
        url: url,
        method: .post,
        parsed: parsed,
        headers: ["Content-Type": "application/json", "Authorization": "Bearer token-value"]
      ),
      captureLevel: .full
    )
  }
}
