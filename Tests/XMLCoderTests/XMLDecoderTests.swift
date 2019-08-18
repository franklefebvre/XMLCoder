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
        
        let result = try! Test.decode(TestStruct.self, from: testXML)
        XCTAssertEqual(result.integer_element, 42)
        XCTAssertEqual(result.string_element, "   moof   & < >   ")
        XCTAssertEqual(result.embedded_element.some_element, "inside")
        XCTAssertEqual(result.string_array, ["one", "two", "three"])
        XCTAssertEqual(result.int_array, [1, 2, 3])
    }
    
    func testAttributes() {
        struct EnclosingStruct: Decodable {
            var container: AttributesStruct
            var top_attribute: String
            
            private enum CodingKeys: String, CodingKey, XMLTypedKey {
                case container
                case top_attribute
                
                var nodeType: XMLNodeType {
                    switch self {
                    case .top_attribute:
                        return .attribute
                    default:
                        return .element
                    }
                }
            }
        }
        
        struct AttributesStruct: Decodable {
            var element: String
            var attribute: String
            var inlineText: String
            var number: Int
            
            private enum CodingKeys: String, CodingKey, XMLTypedKey {
                case element
                case attribute
                case inlineText
                case number
                
                var nodeType: XMLNodeType {
                    switch self {
                    case .attribute:
                        return .attribute
                    case .inlineText:
                        return .inline
                    default:
                        return .element
                    }
                }
            }
        }
        
        let validXML = """
        <root top_attribute="top"><container attribute="attr"><element>elem</element>text<number>42</number></container></root>
        """
        let result = try! Test.decode(EnclosingStruct.self, from: validXML)
        XCTAssertEqual(result.top_attribute, "top")
        XCTAssertEqual(result.container.element, "elem")
        XCTAssertEqual(result.container.attribute, "attr")
        XCTAssertEqual(result.container.inlineText, "text")
        XCTAssertEqual(result.container.number, 42)
        
        let invalidXML1 = """
        <root top_attribute="top"><container><attribute>attr</attribute><element>elem</element>text<number>42</number></container></root>
        """
        XCTAssertThrowsError(try Test.decode(EnclosingStruct.self, from: invalidXML1))
    }
    
    static var allTests = [
        ("testDecodeBasicXML", testDecodeBasicXML),
        ("testAttributes", testAttributes),
    ]
}

