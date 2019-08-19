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
        
        let result = try! Test.decode(BasicTestStruct.self, from: testXML)
        XCTAssertEqual(result.integer_element, 42)
        XCTAssertEqual(result.string_element, "   moof   & < >   ")
        XCTAssertEqual(result.embedded_element.some_element, "inside")
        XCTAssertEqual(result.string_array, ["one", "two", "three"])
        XCTAssertEqual(result.int_array, [1, 2, 3])
    }
    
    func testAttributes() {
        let validXML = """
        <root top_attribute="top"><container attribute="attr"><element>elem</element>text<number>42</number></container></root>
        """
        let result = try! Test.decode(AttributesEnclosingStruct.self, from: validXML)
        XCTAssertEqual(result.top_attribute, "top")
        XCTAssertEqual(result.container.element, "elem")
        XCTAssertEqual(result.container.attribute, "attr")
        XCTAssertEqual(result.container.inlineText, "text")
        XCTAssertEqual(result.container.number, 42)
        
        let invalidXML1 = """
        <root top_attribute="top"><container><attribute>attr</attribute><element>elem</element>text<number>42</number></container></root>
        """
        XCTAssertThrowsError(try Test.decode(AttributesEnclosingStruct.self, from: invalidXML1))
    }
    
    static var allTests = [
        ("testDecodeBasicXML", testDecodeBasicXML),
        ("testAttributes", testAttributes),
    ]
}

