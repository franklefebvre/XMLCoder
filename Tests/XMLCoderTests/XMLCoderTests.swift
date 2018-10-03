import XCTest
@testable import XMLCoder

final class XMLCoderTests: XCTestCase {
    func testEncodeBasicXML() {
		struct TestStruct: Encodable {
			var integer_element: Int
			var string_element: String
			var embedded_element: EmbeddedStruct
			var string_array: [XMLStringElement]
			var int_array: [XMLIntElement]
		}

		struct EmbeddedStruct: Encodable {
			var some_element: String
		}

		let embedded = EmbeddedStruct(some_element: "inside")
		let value = TestStruct(integer_element: 42, string_element: "   moof   & < >   ", embedded_element: embedded, string_array: ["one", "two", "three"], int_array: [1, 2, 3])

		let result = Test.xmlString(value)
		
        let expected = """
        <root>\
        <integer_element>42</integer_element>\
        <string_element>   moof   &amp; &lt; &gt;   </string_element>\
        <embedded_element><some_element>inside</some_element></embedded_element>\
        <string_array><element>one</element><element>two</element><element>three</element></string_array>\
        <int_array><element>1</element><element>2</element><element>3</element></int_array>\
        </root>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
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
        
        let result = Test.xmlString(value)
        
        let expected = """
        <root top_attribute="top"><container attribute="attr"><element>elem</element>text</container></root>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
        
        #if false
        let jsonResult = Test.jsonString(value)
        let jsonExpected = """
        {"container":{"attribute":"attr","element":"elem","inlineText":"text"},"top_attribute":"top"}
        """
        XCTAssertEqual(jsonResult, jsonExpected)
        #endif
    }
    
    struct NamespaceStruct: Encodable {
        var with_namespace: String
        var without_namespace: String
        
        private enum CodingKeys: String, CodingKey, XMLQualifiedKey {
            case with_namespace
            case without_namespace
            
            var namespace: String? {
                switch(self) {
                case .with_namespace:
                    return "http://some.url.example.com/whatever"
                default:
                    return nil
                }
            }
        }
        // extension declaration wouldn't work here (not file scope).
    }
    
    func testNamespaces() {
        let value = NamespaceStruct(with_namespace: "test1", without_namespace: "test2")
        
        let result = Test.xmlString(value)
        
        let expected = """
        <root xmlns:ns1="http://some.url.example.com/whatever">\
        <ns1:with_namespace>test1</ns1:with_namespace>\
        <without_namespace>test2</without_namespace>\
        </root>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
        
        let jsonResult = Test.jsonString(value)
        let jsonExpected = """
        {"with_namespace":"test1","without_namespace":"test2"}
        """
        XCTAssertEqual(jsonResult, jsonExpected)
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
        
        let jsonResult = Test.jsonString(value)
        let jsonExpected = """
        {"with_namespace":"test1","without_namespace":"test2"}
        """
        XCTAssertEqual(jsonResult, jsonExpected)
    }
    
    func testArrayWithKeyedStringElements() {
        struct ArrayStruct: Encodable {
            var string: String
            var children: [ArrayElement]
        }
        
        struct ChildKey: XMLArrayKey {
            static var elementName = "child"
        }
        typealias ArrayElement = XMLArrayElement<ChildKey>
        
        let value = ArrayStruct(string: "some text", children: ["one", "two", "three", "four"])
        
        let result = Test.xmlString(value)
        
        let expected = """
        <root>\
        <string>some text</string>\
        <children><child>one</child><child>two</child><child>three</child><child>four</child></children>\
        </root>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
        
        let jsonResult = Test.jsonString(value)
        let jsonExpected = """
        {"children":[{"child":"one"},{"child":"two"},{"child":"three"},{"child":"four"}],"string":"some text"}
        """
        XCTAssertEqual(jsonResult, jsonExpected)
    }
    
    func testArrayWithAttributes() {
        struct ArrayElementStruct: Encodable, XMLCustomElementMode {
            var id: CodableXMLAttribute
            var inlineText: CodableXMLInlineText
            
            var elementMode: XMLElementMode {
                return .keyed("element")
            }
        }
        
        let value = [
            ArrayElementStruct(id: "1", inlineText: "one"),
            ArrayElementStruct(id: "2", inlineText: "two"),
            ArrayElementStruct(id: "3", inlineText: "three"),
            ArrayElementStruct(id: "4", inlineText: "four"),
        ]
        
        let result = Test.xmlString(value)
        
        let expected = """
        <root>\
        <element id="1">one</element>\
        <element id="2">two</element>\
        <element id="3">three</element>\
        <element id="4">four</element>\
        </root>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
        
        #if false
        let jsonResult = Test.jsonString(value)
        let jsonExpected = """
        [{"id":"1","inlineText":"one"},\
        {"id":"2","inlineText":"two"},\
        {"id":"3","inlineText":"three"},\
        {"id":"4","inlineText":"four"}]
        """
        XCTAssertEqual(jsonResult, jsonExpected)
        #endif
    }
    
    func testArrayWithAlternatingKeysAndValues() {
        struct KeyElement: Encodable {
            let value: CodableXMLInlineText
        }
        struct ValueElement: Encodable {
            let type: CodableXMLAttribute
            let value: CodableXMLInlineText
        }
        struct ArrayElement: Encodable {
            let key: KeyElement
            let value: ValueElement
        }
        
        let value: [ArrayElement] = [
            ArrayElement(key: KeyElement(value: "one"), value: ValueElement(type: "string", value: "value 1")),
            ArrayElement(key: KeyElement(value: "two"), value: ValueElement(type: "integer", value: "2")),
        ]
        
        let result = Test.xmlString(value)
        
        let expected = """
        <root>\
        <key>one</key>\
        <value type="string">value 1</value>\
        <key>two</key>\
        <value type="integer">2</value>\
        </root>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testArrayOfStructs() {
        struct ArrayElement: Encodable, XMLCustomElementMode {
            let field1: String
            let field2: String
            
            var elementMode: XMLElementMode {
                return .keyed("element")
            }
        }
        
        let value = [
            ArrayElement(field1: "first.1", field2: "first.2"),
            ArrayElement(field1: "second.1", field2: "second.2"),
            ArrayElement(field1: "third.1", field2: "third.2"),
            ]
        
        let result = Test.xmlString(value)
        
        let expected = """
        <root>\
        <element><field1>first.1</field1><field2>first.2</field2></element>\
        <element><field1>second.1</field1><field2>second.2</field2></element>\
        <element><field1>third.1</field1><field2>third.2</field2></element>\
        </root>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
        
        let jsonResult = Test.jsonString(value)
        let jsonExpected = """
        [{"field1":"first.1","field2":"first.2"},\
        {"field1":"second.1","field2":"second.2"},\
        {"field1":"third.1","field2":"third.2"}]
        """
        XCTAssertEqual(jsonResult, jsonExpected)
    }
    
    func testArrayOfArrays() {
        let value: [[XMLStringElement]] = [
            ["11", "12", "13"],
            ["21", "22", "23"],
            ["31", "32", "33"],
            ["42"],
        ]
        
        let result = Test.xmlString(value)
        
        let expected = """
        <root>\
        <element><element>11</element><element>12</element><element>13</element></element>\
        <element><element>21</element><element>22</element><element>23</element></element>\
        <element><element>31</element><element>32</element><element>33</element></element>\
        <element><element>42</element></element>\
        </root>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
        
        let jsonResult = Test.jsonString(value)
        let jsonExpected = """
        [["11","12","13"],\
        ["21","22","23"],\
        ["31","32","33"],\
        ["42"]]
        """
        XCTAssertEqual(jsonResult, jsonExpected)
    }
    
    func testNilAsMissing() {
        struct OptionalStruct: Encodable {
            var optionalAttribute: CodableXMLAttribute?
            var mandatoryAttribute: CodableXMLAttribute
            var optionalElement: String?
            var mandatoryElement: String
        }
        
        let value = OptionalStruct(optionalAttribute: nil, mandatoryAttribute: "attr", optionalElement: nil, mandatoryElement: "elem")
        
        let result = Test.xmlString(value)
        
        let expected = """
        <root mandatoryAttribute="attr">\
        <mandatoryElement>elem</mandatoryElement>\
        </root>
        """
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testNilAsEmpty() {
        struct OptionalStruct: Encodable {
            var optionalAttribute: CodableXMLAttribute?
            var mandatoryAttribute: CodableXMLAttribute
            var optionalElement: String?
            var mandatoryElement: String
            
            enum CodingKeys: CodingKey {
                case optionalAttribute
                case mandatoryAttribute
                case optionalElement
                case mandatoryElement
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(optionalAttribute, forKey: .optionalAttribute)
                try container.encode(mandatoryAttribute, forKey: .mandatoryAttribute)
                try container.encode(optionalElement, forKey: .optionalElement)
                try container.encode(mandatoryElement, forKey: .mandatoryElement)
            }
        }
        
        let value = OptionalStruct(optionalAttribute: nil, mandatoryAttribute: "attr", optionalElement: nil, mandatoryElement: "elem")
        
        let encoder = XMLEncoder()
        encoder.nilEncodingStrategy = .empty
        let xml = try! encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)!
        
        let expected = """
        <root optionalAttribute="" mandatoryAttribute="attr">\
        <optionalElement></optionalElement>\
        <mandatoryElement>elem</mandatoryElement>\
        </root>
        """
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testFloatAndDouble() {
        struct FloatDoubleStruct: Encodable {
            var f: Float
            var d: Double
        }
        
        let value = FloatDoubleStruct(f: 1e-10, d: 1e-15)
        
        let result = Test.xmlString(value)
        let expected = """
        <root>\
        <f>0.0000000001</f>\
        <d>0.000000000000001</d>\
        </root>
        """
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    static var allTests = [
        ("testEncodeBasicXML", testEncodeBasicXML),
        ("testAttributes", testAttributes),
        ("testNamespaces", testNamespaces),
        ("testNamespacesWithOptions", testNamespacesWithOptions),
        ("testArrayWithKeyedStringElements", testArrayWithKeyedStringElements),
        ("testArrayWithAttributes", testArrayWithAttributes),
        ("testArrayWithAlternatingKeysAndValues", testArrayWithAlternatingKeysAndValues),
        ("testArrayOfStructs", testArrayOfStructs),
        ("testArrayOfArrays", testArrayOfArrays),
        ("testNilAsMissing", testNilAsMissing),
        ("testNilAsEmpty", testNilAsEmpty),
        ("testFloatAndDouble", testFloatAndDouble),
    ]
}
