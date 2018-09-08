import XCTest
@testable import XMLCoder

extension String {
    func substringWithXMLTag(_ tag: String) -> Substring? {
        let start = "<\(tag)"
        let end = "</\(tag)>"
        guard let startRange = self.range(of: start) else { return nil }
        guard let endRange = self.range(of: end) else { return nil }
        return self[startRange.lowerBound..<endRange.upperBound]
    }
}

final class XMLCoderTests: XCTestCase {
    func testEncodeBasicXML() {
		struct TestStruct: Encodable {
			var integer_element: Int
			var string_element: String
			var embedded_element: EmbeddedStruct
			var string_array: [String]
			var int_array: [Int]
		}

		struct EmbeddedStruct: Encodable {
			var some_element: String
		}

		let embedded = EmbeddedStruct(some_element: "inside")
		let value = TestStruct(integer_element: 42, string_element: "   moof   & < >   ", embedded_element: embedded, string_array: ["one", "two", "three"], int_array: [1, 2, 3])

		let encoder = XMLEncoder()
		let xml = try! encoder.encode(value)
		let result = String(data: xml.xmlData, encoding: .utf8)
		
        let expected = """
        <root>\
        <integer_element>42</integer_element>\
        <string_element>   moof   &amp; &lt; &gt;   </string_element>\
        <embedded_element><some_element>inside</some_element></embedded_element>\
        <string_array><element>one</element><element>two</element><element>three</element></string_array>\
        <int_array><element>1</element><element>2</element><element>3</element></int_array>\
        </root>
        """
        
        XCTAssertEqual(result?.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testWhitespace() throws {
        let initialString = """
        <whitespace xml:space="preserve">   a   b   c
        d   e   f   </whitespace>
        """
        let xml = try XMLDocument(xmlString: initialString)
        let finalString = String(data: xml.xmlData, encoding: .utf8)
        XCTAssertEqual(initialString.substringWithXMLTag("whitespace"), finalString?.substringWithXMLTag("whitespace"))
    }
    
    func testAttributes() {
        struct EnclosingStruct: Encodable {
            var container: AttributesStruct
        }
        struct AttributesStruct: Encodable {
            var element: String
            var attribute: CodableXMLAttribute
        }
        
        let value = EnclosingStruct(container: AttributesStruct(element: "elem", attribute: "attr"))
        let encoder = XMLEncoder()
        let xml = try! encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)
        
        let expected = """
        <root><container attribute="attr"><element>elem</element></container></root>
        """
        
        XCTAssertEqual(result?.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }


    static var allTests = [
        ("testEncodeBasicXML", testEncodeBasicXML),
        ("testWhitespace", testWhitespace),
        ("testAttributes", testAttributes),
    ]
}
