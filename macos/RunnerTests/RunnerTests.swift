import Cocoa
import FlutterMacOS
@testable import Runner
import XCTest

class RunnerTests: XCTestCase {

  func testRunShellScriptSuccess() {
    let delegate = AppDelegate()
    let expectation = XCTestExpectation(description: "shell")
    delegate.runShellScript(command: "echo hello", returnsBool: false) { result in
      if let str = result as? String {
        XCTAssertEqual(str, "success")
      } else {
        XCTFail("Unexpected result")
      }
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 5.0)
  }
}
