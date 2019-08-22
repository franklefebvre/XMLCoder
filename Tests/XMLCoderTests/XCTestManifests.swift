import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(XMLTests.allTests),
        testCase(XMLEncoderTests.allTests),
        testCase(XMLDecoderTests.allTests),
    ]
}
#endif
