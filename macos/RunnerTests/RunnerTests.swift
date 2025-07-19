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

  func testHandlePerformActionIsDownloading() {
    let delegate = AppDelegate()
    let call = FlutterMethodCall(methodName: "performAction", arguments: ["action": "isXrayDownloading"])
    let expectation = XCTestExpectation(description: "performAction")
    delegate.handlePerformAction(call: call, bundleId: "com.xstream.test") { result in
      if let str = result as? String {
        XCTAssertEqual(str, "0")
      } else {
        XCTFail("Unexpected result")
      }
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 5.0)
  }

  func testHandlePerformActionInvalidArgs() {
    let delegate = AppDelegate()
    let call = FlutterMethodCall(methodName: "performAction", arguments: nil)
    let expectation = XCTestExpectation(description: "invalidArgs")
    delegate.handlePerformAction(call: call, bundleId: "com.xstream.test") { result in
      if let err = result as? FlutterError {
        XCTAssertEqual(err.code, "INVALID_ARGS")
      } else {
        XCTFail("Expected FlutterError")
      }
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 5.0)
  }
}
