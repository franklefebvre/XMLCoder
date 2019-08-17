import XCTest
@testable import XMLCoder

final class XMLDecoderTests: XCTestCase {
    func testDecodeBasicXML() {
        let testXML = """
        <root>\
        <integer_element>42</integer_element>\
        <string_element>   moof   &amp; &lt; &gt;   </string_element>\
        <embedded_element><some_element>inside</some_element></embedded_element>\
        <string_array><element>one</element><element>two</element><element>three</element></string_array>\
        <int_array><element>1</element><element>2</element><element>3</element></int_array>\
        </root>
        """
        
        struct TestStruct: Decodable {
            var integer_element: Int
            var string_element: String
            var embedded_element: EmbeddedStruct
            var string_array: [String]
            var int_array: [Int]
        }
        
        struct EmbeddedStruct: Decodable {
            var some_element: String
        }
        
        let result = Test.decode(TestStruct.self, from: testXML)
        XCTAssertEqual(result.integer_element, 42)
        XCTAssertEqual(result.string_element, "   moof   & < >   ")
        XCTAssertEqual(result.embedded_element.some_element, "inside")
        XCTAssertEqual(result.string_array, ["one", "two", "three"])
        XCTAssertEqual(result.int_array, [1, 2, 3])
    }
    
    static var allTests = [
        ("testDecodeBasicXML", testDecodeBasicXML),
    ]
}

