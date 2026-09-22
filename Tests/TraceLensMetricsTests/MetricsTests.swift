import XCTest
@testable import TraceLensMetrics
@testable import TraceLensCore

final class MetricsTests: XCTestCase { func testAggregate() throws { let url = try XCTUnwrap(URL(string: "https://api.example.test/a")); let parsed = EndpointParser().parse(url); var transaction = NetworkTransaction(startedAt: Date(timeIntervalSince1970: 0), request: .init(url: url, method: .get, parsed: parsed), captureLevel: .full); transaction.finishedAt = Date(timeIntervalSince1970: 1); transaction.response = .init(statusCode: 200); let metrics = MetricsAggregator().aggregate([transaction]); XCTAssertEqual(metrics.totalRequests, 1); XCTAssertEqual(metrics.fullCaptureRatio, 1); XCTAssertEqual(metrics.averageDuration, 1) } }
