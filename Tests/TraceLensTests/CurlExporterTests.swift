import Foundation
import XCTest
@testable import TraceLens
import TraceLensCore

final class CurlExporterTests: XCTestCase {
  func testBFFCommandUsesConfiguredHostEndpointQueryAndBearer() throws {
    let command = try CurlExporter.bffCommand(
      for: transaction(),
      bodyData: Data("{\"amount\":100}".utf8),
      destination: .init(host: "payment-service.dev.example.com")
    )

    XCTAssertEqual(
      command,
      "curl -X POST 'https://payment-service.dev.example.com/v1/payments?dryRun=true' -H 'Authorization: Bearer token-value' -H 'Content-Type: application/json' --data-raw '{\"amount\":100}'"
    )
  }

  func testBFFCommandIncludesOptionalIntermediatePath() throws {
    XCTAssertTrue(try CurlExporter.bffCommand(
      for: transaction(),
      bodyData: nil,
      destination: .init(host: "payment-service.uat.example.com", intermediatePath: "/api/bff/")
    ).contains("https://payment-service.uat.example.com/api/bff/v1/payments?dryRun=true"))
  }

  func testBFFCommandUsesLocalhostPortWithoutTechnicalComponent() throws {
    XCTAssertTrue(try CurlExporter.bffCommand(
      for: transaction(),
      bodyData: nil,
      destination: .init(host: "localhost:8080")
    ).contains("http://localhost:8080/v1/payments?dryRun=true"))
  }

  func testBFFCommandRequiresBearerToken() throws {
    var value = transaction()
    value.request.headers = [:]
    XCTAssertThrowsError(try CurlExporter.bffCommand(
      for: value,
      bodyData: nil,
      destination: .init(host: "payment-service.dev.example.com")
    )) {
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
