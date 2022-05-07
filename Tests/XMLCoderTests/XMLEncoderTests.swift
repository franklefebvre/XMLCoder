import XCTest
#if os(Linux)
import FoundationXML
#endif
@testable import XMLCoder

final class XMLEncoderTests: XCTestCase {
    func testEncodeBasicXML() {
		let embedded = BasicEmbeddedStruct(some_element: "inside")
		let value = BasicTestStruct(integer_element: 42, string_element: "   moof   & < >   ", embedded_element: embedded, string_array: ["one", "two", "three"], int_array: [1, 2, 3])

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
        let contents = AttributesStruct(element: "elem", attribute: "attr", inlineText: "text", number: 42)
        let value = AttributesEnclosingStruct(container: contents, top_attribute: "top")
        
        let result = Test.xmlString(value)
        
        let expected = """
        <root top_attribute="top"><container attribute="attr"><element>elem</element>text<number>42</number></container></root>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
        
        let jsonResult = Test.jsonString(value)
        let jsonExpected = """
        {"container":{"attribute":"attr","element":"elem","inlineText":"text","number":42},"top_attribute":"top"}
        """
        XCTAssertEqual(jsonResult, jsonExpected)
    }
    
    func testInlineText() {
        let value = ElementsWithInlineText(inline0:"zero", stringElement: "string", inline1: "one", intElement: 42, inline2: 2)
        
        let result = Test.xmlString(value)
        
        let expected = """
        <root>zero<stringElement>string</stringElement>one<intElement>42</intElement>2</root>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
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
        let encoder = XMLEncoder(documentRootTag: "root")
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
        {"children":["one","two","three","four"],"string":"some text"}
        """
        XCTAssertEqual(jsonResult, jsonExpected)
    }
    
    func testArrayWithAttributes() {
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
        
        let jsonResult = Test.jsonString(value)
        let jsonExpected = """
        [{"id":"1","inlineText":"one"},\
        {"id":"2","inlineText":"two"},\
        {"id":"3","inlineText":"three"},\
        {"id":"4","inlineText":"four"}]
        """
        XCTAssertEqual(jsonResult, jsonExpected)
    }
    
    func testArrayWithAlternatingKeysAndValues() {
        let value = AlternatingRoot(array: [
            AlternatingArrayElement(key: AlternatingKeyElement(value: "one"), value: AlternatingValueElement(type: "string", value: "value 1")),
            AlternatingArrayElement(key: AlternatingKeyElement(value: "two"), value: AlternatingValueElement(type: "integer", value: "2")),
        ])
        
        let result = Test.xmlString(value)
        
        let expected = """
        <root><array>\
        <key>one</key>\
        <value type="string">value 1</value>\
        <key>two</key>\
        <value type="integer">2</value>\
        </array></root>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testArrayOfStructs() {
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
        let value: [[String]] = [
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
        let value = OptionalStruct(optionalAttribute: nil, mandatoryAttribute: "attr", optionalElement: nil, mandatoryElement: "elem")
        
        let encoder = XMLEncoder(documentRootTag: "root")
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
    
    func testDateAndURL() {
        let date = Date(timeIntervalSince1970: 1)
        let url = URL(string: "https://swift.org/")!
        let value = DateURLStruct(date: date, dates: [date, date], url: url, urls: [url, url])
        
        let result = Test.xmlString(value)
        
        let expected = """
        <root>\
        <date>1970-01-01T00:00:00Z</date>\
        <dates><element>1970-01-01T00:00:00Z</element><element>1970-01-01T00:00:00Z</element></dates>\
        <url>https://swift.org/</url>\
        <urls><element>https://swift.org/</element><element>https://swift.org/</element></urls>\
        </root>
        """
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testDateWithFormat() throws {
        let date123 = Date(timeIntervalSince1970: 0.123)
        let date456 = Date(timeIntervalSince1970: 0.456)
        let date789 = Date(timeIntervalSince1970: 0.789)
        let url = URL(string: "https://swift.org/")!
        let value = DateURLStruct(date: date123, dates: [date456, date789], url: url, urls: [])
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSXX"
        
        let encoder = XMLEncoder(documentRootTag: "root")
        encoder.dateEncodingStrategy = .formatted(formatter)
        let xml = try encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)!
        
        let expected = """
        <root>\
        <date>1970-01-01T00:00:00.123Z</date>\
        <dates><element>1970-01-01T00:00:00.456Z</element><element>1970-01-01T00:00:00.789Z</element></dates>\
        <url>https://swift.org/</url>\
        <urls></urls>\
        </root>
        """
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testBoolWithDefaultStrategy() {
        let value = BoolStruct(test: true, tests: [false, true, false])
        
        let result = Test.xmlString(value)
        let expected = """
        <root>\
        <test>1</test>\
        <tests><element>0</element><element>1</element><element>0</element></tests>\
        </root>
        """
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testBoolWithCustomStrategy() {
        let value = BoolStruct(test: true, tests: [false, true, false])
        
        let encoder = XMLEncoder(documentRootTag: "root")
        encoder.boolEncodingStrategy = XMLEncoder.BoolEncodingStrategy(falseValue: "no", trueValue: "yes")
        let xml = try! encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)!
        
        let expected = """
        <root>\
        <test>yes</test>\
        <tests><element>no</element><element>yes</element><element>no</element></tests>\
        </root>
        """
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testData() {
        let data = Data([0x42, 0x00, 0xff])
        let value = DataStruct(element: data, elements: [data, data])
        
        let result = Test.xmlString(value)
        let expected = """
        <root>\
        <element>QgD/</element>\
        <elements><element>QgD/</element><element>QgD/</element></elements>\
        </root>
        """
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testDataToHex() throws {
        let data = Data([0x42, 0x00, 0xff])
        let value = DataStruct(element: data, elements: [data, data])
        
        let encoder = XMLEncoder(documentRootTag: "root")
        encoder.dataEncodingStrategy = .hex(uppercase: false)
        let xml = try encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)!
        
        let expected = """
        <root>\
        <element>4200ff</element>\
        <elements><element>4200ff</element><element>4200ff</element></elements>\
        </root>
        """
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testSubclass() {
        let value = Subclass()
        value.base = "base"
        value.sub = "sub"
        
        let result = Test.xmlString(value)
        let expected = """
        <root>\
        <base>base</base>\
        <sub>sub</sub>\
        </root>
        """
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testDocumentRootTag() {
        let value = OneTagTestStruct(tag: "value")
        
        let encoder = XMLEncoder(documentRootTag: "another_root")
        let xml = try! encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)!
        
        let expected = """
        <another_root>\
        <tag>value</tag>\
        </another_root>
        """
        XCTAssertEqual(result.substringWithXMLTag("another_root"), expected.substringWithXMLTag("another_root"))
    }
    
    func testUppercaseKeys() throws {
        func uppercaseKey(_ codingPath: [CodingKey]) -> String {
            return codingPath.last?.stringValue.uppercased() ?? ""
        }
        
        let value = BasicTestStruct(integer_element: 123, string_element: "hello", embedded_element: BasicEmbeddedStruct(some_element: "embedded"), string_array: ["one", "two", "three"], int_array: [1, 2, 3])

        let encoder = XMLEncoder(documentRootTag: "ROOT")
        encoder.keyCodingStrategy = .custom(uppercaseKey)
        let xml = try encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)!
        
        let expected = """
        <ROOT>\
        <INTEGER_ELEMENT>123</INTEGER_ELEMENT>\
        <STRING_ELEMENT>hello</STRING_ELEMENT>\
        <EMBEDDED_ELEMENT><SOME_ELEMENT>embedded</SOME_ELEMENT></EMBEDDED_ELEMENT>\
        <STRING_ARRAY>\
        <element>one</element>\
        <element>two</element>\
        <element>three</element>\
        </STRING_ARRAY>\
        <INT_ARRAY>\
        <element>1</element>\
        <element>2</element>\
        <element>3</element>\
        </INT_ARRAY>\
        </ROOT>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("ROOT"), expected.substringWithXMLTag("ROOT"))
    }
    
    func testUppercaseElements() throws {
        func uppercaseKey(_ codingPath: [CodingKey]) -> String {
            return codingPath.last?.stringValue.uppercased() ?? ""
        }
        
        let value = AttributesStruct(element: "element_value", attribute: "attribute_value", inlineText: "inline_value", number: 42)
        
        let encoder = XMLEncoder(documentRootTag: "ROOT")
        encoder.elementNameCodingStrategy = .custom(uppercaseKey)
        let xml = try encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)!
        
        let expected = """
        <ROOT attribute="attribute_value">\
        <ELEMENT>element_value</ELEMENT>inline_value<NUMBER>42</NUMBER>\
        </ROOT>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("ROOT"), expected.substringWithXMLTag("ROOT"))
    }
    
    func testUppercaseAttributes() throws {
        func uppercaseKey(_ codingPath: [CodingKey]) -> String {
            return codingPath.last?.stringValue.uppercased() ?? ""
        }
        
        let value = AttributesStruct(element: "element_value", attribute: "attribute_value", inlineText: "inline_value", number: 42)
        
        let encoder = XMLEncoder(documentRootTag: "root")
        encoder.attributeNameCodingStrategy = .custom(uppercaseKey)
        let xml = try encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)!
        
        let expected = """
        <root ATTRIBUTE="attribute_value">\
        <element>element_value</element>inline_value<number>42</number>\
        </root>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
    }
    
    func testUppercaseElementsAndAttributes() throws {
        func uppercaseKey(_ codingPath: [CodingKey]) -> String {
            return codingPath.last?.stringValue.uppercased() ?? ""
        }
        
        let value = AttributesStruct(element: "element_value", attribute: "attribute_value", inlineText: "inline_value", number: 42)
        
        let encoder = XMLEncoder(documentRootTag: "ROOT")
        encoder.keyCodingStrategy = .custom(uppercaseKey)
        let xml = try encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)!
        
        let expected = """
        <ROOT ATTRIBUTE="attribute_value">\
        <ELEMENT>element_value</ELEMENT>inline_value<NUMBER>42</NUMBER>\
        </ROOT>
        """
        
        XCTAssertEqual(result.substringWithXMLTag("ROOT"), expected.substringWithXMLTag("ROOT"))
    }
    
    static var allTests = [
        ("testEncodeBasicXML", testEncodeBasicXML),
        ("testAttributes", testAttributes),
        ("testInlineText", testInlineText),
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
        ("testDateAndURL", testDateAndURL),
        ("testDateWithFormat", testDateWithFormat),
        ("testBoolWithDefaultStrategy", testBoolWithDefaultStrategy),
        ("testBoolWithCustomStrategy", testBoolWithCustomStrategy),
        ("testData", testData),
        ("testDataToHex", testDataToHex),
        ("testSubclass", testSubclass),
        ("testDocumentRootTag", testDocumentRootTag),
        ("testUppercaseKeys", testUppercaseKeys),
        ("testUppercaseElements", testUppercaseElements),
        ("testUppercaseAttributes", testUppercaseAttributes),
        ("testUppercaseElementsAndAttributes", testUppercaseElementsAndAttributes),
    ]
}
