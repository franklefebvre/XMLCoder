import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(XMLTests.allTests),
        testCase(XMLCoderTests.allTests),
        testCase(XMLDecoderTests.allTests),
    ]
}
#endif
