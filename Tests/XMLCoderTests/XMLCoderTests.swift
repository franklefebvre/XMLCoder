import XCTest
@testable import XMLCoder

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
    
    func testAttributes() {
        struct EnclosingStruct: Encodable {
            var container: AttributesStruct
            var top_attribute: CodableXMLAttribute
        }
        struct AttributesStruct: Encodable {
            var element: String
            var attribute: CodableXMLAttribute
            var inlineText: CodableXMLInlineText
        }
        
        let value = EnclosingStruct(container: AttributesStruct(element: "elem", attribute: "attr", inlineText: "text"), top_attribute: "top")
        let encoder = XMLEncoder()
        let xml = try! encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)
        
        let expected = """
        <root top_attribute="top"><container attribute="attr"><element>elem</element>text</container></root>
        """
        
        XCTAssertEqual(result?.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    struct NamespaceStruct: Encodable {
        var with_namespace: String
        var without_namespace: String
        
        private enum CodingKeys: String, CodingKey, XMLQualifiedKey {
            case with_namespace
            case without_namespace
            
            var namespace: String? { get {
                switch(self) {
                case .with_namespace:
                    return "http://some.url.example.com/whatever"
                default:
                    return nil
                }
                }}
        }
        // extension declaration wouldn't work here (not file scope).
    }
    
    func testNamespaces() {
        let value = NamespaceStruct(with_namespace: "test1", without_namespace: "test2")
        let encoder = XMLEncoder()
        let xml = try! encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)
        
        let expected = """
        <root xmlns:ns1="http://some.url.example.com/whatever">\
        <ns1:with_namespace>test1</ns1:with_namespace>\
        <without_namespace>test2</without_namespace>\
        </root>
        """
        
        XCTAssertEqual(result?.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testNamespacesWithOptions() {
        let value = NamespaceStruct(with_namespace: "test1", without_namespace: "test2")
        let encoder = XMLEncoder()
        encoder.defaultNamespace = "http://some.url.example.com/default"
        encoder.namespacePrefix = "nsns"
        let xml = try! encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)
        
        let expected = """
        <root xmlns="http://some.url.example.com/default" xmlns:nsns1="http://some.url.example.com/whatever">\
        <nsns1:with_namespace>test1</nsns1:with_namespace>\
        <without_namespace>test2</without_namespace>\
        </root>
        """
        
        XCTAssertEqual(result?.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testArray() {
        struct ArrayStruct: Encodable {
            var string: String
            var children: [ArrayElementStruct]
        }
        struct ArrayElementStruct: ExpressibleByStringLiteral, Encodable {
            var child: String
            init(stringLiteral: StringLiteralType) {
                self.child = stringLiteral
            }
        }
        
        let value = ArrayStruct(string: "some text", children: ["one", "two", "three", "four"])
        let encoder = XMLEncoder()
        let xml = try! encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)
        
        let expected = """
        <root>\
        <string>some text</string>\
        <children><child>one</child><child>two</child><child>three</child><child>four</child></children>\
        </root>
        """
        
        XCTAssertEqual(result?.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testArrayWithAttributes() {
        struct ArrayElementStruct: Encodable {
            var id: CodableXMLAttribute
            var inlineText: CodableXMLInlineText
        }
        
        let value = [
            ArrayElementStruct(id: "1", inlineText: "one"),
            ArrayElementStruct(id: "2", inlineText: "two"),
            ArrayElementStruct(id: "3", inlineText: "three"),
            ArrayElementStruct(id: "4", inlineText: "four"),
        ]
        let encoder = XMLEncoder()
        let xml = try! encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)
        
        let expected = """
        <root>\
        <element id="1">one</element>\
        <element id="2">two</element>\
        <element id="3">three</element>\
        <element id="4">four</element>\
        </root>
        """
        
        XCTAssertEqual(result?.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    static var allTests = [
        ("testEncodeBasicXML", testEncodeBasicXML),
        ("testAttributes", testAttributes),
        ("testNamespaces", testNamespaces),
        ("testNamespacesWithOptions", testNamespacesWithOptions),
        ("testArray", testArray),
        ("testArrayWithAttributes", testArrayWithAttributes),
    ]
}
