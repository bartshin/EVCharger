import XCTest

import EV_APITests

var tests = [XCTestCaseEntry]()
tests += EV_APITests.allTests()
XCTMain(tests)
