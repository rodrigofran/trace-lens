import XCTest
@testable import TraceLensCapture

final class CaptureTests: XCTestCase { func testInstrumentationPreservesClassesAndRejectsMarker() throws { let configuration = URLSessionConfiguration.ephemeral; let instrumented = URLSessionInstrumentation.instrument(configuration); XCTAssertTrue((instrumented.protocolClasses ?? []).contains { $0 == TraceLensURLProtocol.self }); let url = try XCTUnwrap(URL(string: "https://api.example.test/a")); let request = URLRequest(url: url); XCTAssertTrue(TraceLensURLProtocol.canInit(with: request)); let marked = NSMutableURLRequest(url: url); URLProtocol.setProperty(true, forKey: "com.tracelens.handled", in: marked); XCTAssertFalse(TraceLensURLProtocol.canInit(with: marked as URLRequest)) } }
