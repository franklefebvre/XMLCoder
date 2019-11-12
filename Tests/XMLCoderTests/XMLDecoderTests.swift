import XCTest
#if os(Linux)
import FoundationXML
#endif
@testable import XMLCoder

final class XMLDecoderTests: XCTestCase {
    func testDecodeBasicXML() throws {
        let testXML = """
        <root>\
        <integer_element>42</integer_element>\
        <string_element>   moof   &amp; &lt; &gt;   </string_element>\
        <embedded_element><some_element>inside</some_element></embedded_element>\
        <string_array><element>one</element><element>two</element><element>three</element></string_array>\
        <int_array><element>1</element><element>2</element><element>3</element></int_array>\
        </root>
        """
        
        let result = try Test.decode(BasicTestStruct.self, from: testXML)
        XCTAssertEqual(result.integer_element, 42)
        XCTAssertEqual(result.string_element, "   moof   & < >   ")
        XCTAssertEqual(result.embedded_element.some_element, "inside")
        XCTAssertEqual(result.string_array, ["one", "two", "three"])
        XCTAssertEqual(result.int_array, [1, 2, 3])
    }
    
    func testAttributes() throws {
        let xml = """
        <root top_attribute="top"><container attribute="attr"><element>elem</element>text<number>42</number></container></root>
        """
        let result = try Test.decode(AttributesEnclosingStruct.self, from: xml)
        XCTAssertEqual(result.top_attribute, "top")
        XCTAssertEqual(result.container.element, "elem")
        XCTAssertEqual(result.container.attribute, "attr")
        XCTAssertEqual(result.container.inlineText, "text")
        XCTAssertEqual(result.container.number, 42)
    }
    
    func testAttributesError() {
        let xml = """
        <root top_attribute="top"><container><attribute>attr</attribute><element>elem</element>text<number>42</number></container></root>
        """
        XCTAssertThrowsError(try Test.decode(AttributesEnclosingStruct.self, from: xml)) {
            error in
            guard let error = error as? DecodingError else {
                XCTFail("Unexpected error type.")
                return
            }
            switch error {
            case .valueNotFound(_, let context):
                XCTAssertEqual(context.codingPath.map { $0.stringValue }, ["container"])
                XCTAssertEqual(context.debugDescription, "No value associated with key attribute.")
            default:
                XCTFail("Unexpected error value: \(error).")
            }
        }
    }
    
    func testInlineText() throws {
        let xml = """
        <root>zero<stringElement>string</stringElement>one<intElement>42</intElement>2</root>
        """
        let result = try Test.decode(ElementsWithInlineText.self, from: xml)
        XCTAssertEqual(result.inline0, "zero")
        XCTAssertEqual(result.stringElement, "string")
        XCTAssertEqual(result.inline1, "one")
        XCTAssertEqual(result.intElement, 42)
        XCTAssertEqual(result.inline2, 2)
    }
    
    func testNamespaces() throws {
        let xml = """
        <root xmlns:ns1="http://some.url.example.com/whatever">\
        <ns1:with_namespace>test1</ns1:with_namespace>\
        <without_namespace>test2</without_namespace>\
        </root>
        """
        let result = try Test.decode(NamespaceStruct.self, from: xml)
        XCTAssertEqual(result.with_namespace, "test1")
        XCTAssertEqual(result.without_namespace, "test2")
    }
    
    func testNamespacesErrorMissingNamespace() {
        let xml = """
        <root xmlns:ns1="http://some.url.example.com/whatever">\
        <with_namespace>test1</with_namespace>\
        <without_namespace>test2</without_namespace>\
        </root>
        """
        XCTAssertThrowsError(try Test.decode(NamespaceStruct.self, from: xml)) {
            error in
            guard let error = error as? DecodingError else {
                XCTFail("Unexpected error type.")
                return
            }
            switch error {
            case .valueNotFound(_, let context):
                XCTAssertEqual(context.codingPath.map { $0.stringValue }, [])
                XCTAssertEqual(context.debugDescription, "No value associated with key with_namespace.")
            default:
                XCTFail("Unexpected error value: \(error).")
            }
        }
    }
    
    func testNamespacesErrorUnexpectedNamespace() {
        let xml = """
        <root xmlns:ns1="http://some.url.example.com/whatever">\
        <ns1:with_namespace>test1</ns1:with_namespace>\
        <ns1:without_namespace>test2</ns1:without_namespace>\
        </root>
        """
        XCTAssertThrowsError(try Test.decode(NamespaceStruct.self, from: xml)) {
            error in
            guard let error = error as? DecodingError else {
                XCTFail("Unexpected error type.")
                return
            }
            switch error {
            case .valueNotFound(_, let context):
                XCTAssertEqual(context.codingPath.map { $0.stringValue }, [])
                XCTAssertEqual(context.debugDescription, "No value associated with key without_namespace.")
            default:
                XCTFail("Unexpected error value: \(error).")
            }
        }
    }
    
    func testNamespacesWithOptions() throws {
        let xml = """
        <root xmlns="http://some.url.example.com/default" xmlns:nsns1="http://some.url.example.com/whatever">\
        <nsns1:with_namespace>test1</nsns1:with_namespace>\
        <without_namespace>test2</without_namespace>\
        </root>
        """
        
        let document = try XMLDocument(xmlString: xml)
        let decoder = XMLDecoder()
        decoder.defaultNamespace = "http://some.url.example.com/default"
        
        let result = try decoder.decode(NamespaceStruct.self, from: document)
        
        XCTAssertEqual(result.with_namespace, "test1")
        XCTAssertEqual(result.without_namespace, "test2")
    }
    
    func testArrayWithKeyedStringElements() throws {
        let xml = """
        <root>\
        <string>some text</string>\
        <children><child>one</child><child>two</child><child>three</child><child>four</child></children>\
        </root>
        """
        
        let result = try Test.decode(ArrayStruct.self, from: xml)
        XCTAssertEqual(result.string, "some text")
        XCTAssertEqual(result.children, ["one", "two", "three", "four"])
    }
    
    func testArrayWithKeyedStringElementsUnexpectedKeys() throws {
        let xml = """
        <root>\
        <string>some text</string>\
        <children><bad>one</bad><bad>two</bad><bad>three</bad><bad>four</bad></children>\
        </root>
        """
        
        let result = try Test.decode(ArrayStruct.self, from: xml)
        XCTAssertEqual(result.string, "some text")
        XCTAssertEqual(result.children, [])
    }
    
    func testArrayWithAttributes() throws {
        let xml = """
        <root>\
        <element id="1">one</element>\
        <element id="2">two</element>\
        <element id="3">three</element>\
        <element id="4">four</element>\
        </root>
        """
        
        let result = try Test.decode([ArrayElementStruct].self, from: xml)
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].id, "1")
        XCTAssertEqual(result[0].inlineText, "one")
        XCTAssertEqual(result[1].id, "2")
        XCTAssertEqual(result[1].inlineText, "two")
        XCTAssertEqual(result[2].id, "3")
        XCTAssertEqual(result[2].inlineText, "three")
        XCTAssertEqual(result[3].id, "4")
        XCTAssertEqual(result[3].inlineText, "four")
    }
    
    // Not implemented yet...
    #if false
    func testArrayWithAlternatingKeysAndValues() throws {
        let xml = """
        <root><array>\
        <key>one</key>\
        <value type="string">value 1</value>\
        <key>two</key>\
        <value type="integer">2</value>\
        </array></root>
        """
        
        let result = try Test.decode(AlternatingRoot.self, from: xml)
        XCTAssertEqual(result.array.count, 2)
        if (result.array.count == 2) {
            XCTAssertEqual(result.array[0].key.value, "one")
            XCTAssertEqual(result.array[0].value.type, "string")
            XCTAssertEqual(result.array[0].value.value, "value 1")
            XCTAssertEqual(result.array[1].key.value, "two")
            XCTAssertEqual(result.array[1].value.type, "integer")
            XCTAssertEqual(result.array[1].value.value, "2")
        }
    }
    #endif
    
    func testArrayOfStructs() throws {
        let xml = """
        <root>\
        <element><field1>first.1</field1><field2>first.2</field2></element>\
        <element><field1>second.1</field1><field2>second.2</field2></element>\
        <element><field1>third.1</field1><field2>third.2</field2></element>\
        </root>
        """
        
        let result = try Test.decode([ArrayElement].self, from: xml)
        XCTAssertEqual(result.count, 3)
        if (result.count == 3) {
            XCTAssertEqual(result[0].field1, "first.1")
            XCTAssertEqual(result[0].field2, "first.2")
            XCTAssertEqual(result[1].field1, "second.1")
            XCTAssertEqual(result[1].field2, "second.2")
            XCTAssertEqual(result[2].field1, "third.1")
            XCTAssertEqual(result[2].field2, "third.2")
        }
    }
    
    func testArrayOfArrays() throws {
        let xml = """
        <root>\
        <element><element>11</element><element>12</element><element>13</element></element>\
        <element><element>21</element><element>22</element><element>23</element></element>\
        <element><element>31</element><element>32</element><element>33</element></element>\
        <element><element>42</element></element>\
        </root>
        """
        
        let result = try Test.decode([[String]].self, from: xml)
        
        let expected: [[String]] = [
            ["11", "12", "13"],
            ["21", "22", "23"],
            ["31", "32", "33"],
            ["42"],
        ]
        XCTAssertEqual(result, expected)
    }
    
    func testNilAsMissing() throws {
        let xml = """
        <root mandatoryAttribute="attr">\
        <mandatoryElement>elem</mandatoryElement>\
        </root>
        """
        
        let result = try Test.decode(OptionalStruct.self, from: xml)
        
        XCTAssertNil(result.optionalAttribute)
        XCTAssertEqual(result.mandatoryAttribute, "attr")
        XCTAssertNil(result.optionalElement)
        XCTAssertEqual(result.mandatoryElement, "elem")
    }
    
    func testNilAsEmpty() throws {
        let xml = """
        <root optionalAttribute="" mandatoryAttribute="attr">\
        <optionalElement></optionalElement>\
        <mandatoryElement>elem</mandatoryElement>\
        </root>
        """
        
        let document = try XMLDocument(xmlString: xml)
        let decoder = XMLDecoder()
        decoder.nilDecodingStrategy = .empty
        
        let result = try decoder.decode(OptionalStruct.self, from: document)
        
        XCTAssertNil(result.optionalAttribute)
        XCTAssertEqual(result.mandatoryAttribute, "attr")
        XCTAssertNil(result.optionalElement)
        XCTAssertEqual(result.mandatoryElement, "elem")
    }
    
    func testFloatAndDouble() throws {
        let xml = """
        <root>\
        <f>0.0000000001</f>\
        <d>0.000000000000001</d>\
        </root>
        """
        
        let result = try Test.decode(FloatDoubleStruct.self, from: xml)
        
        XCTAssertEqual(result.f, 1e-10)
        XCTAssertEqual(result.d, 1e-15)
    }
    
    func testDateAndURL() throws {
        let xml = """
        <root>\
        <date>1970-01-01T00:00:00Z</date>\
        <dates><element>1970-01-01T00:00:00Z</element><element>1970-01-01T00:00:00Z</element></dates>\
        <url>https://swift.org/</url>\
        <urls><element>https://swift.org/</element><element>https://swift.org/</element></urls>\
        </root>
        """
        
        let result = try Test.decode(DateURLStruct.self, from: xml)
        
        let date = Date(timeIntervalSince1970: 0)
        let url = URL(string: "https://swift.org/")!
        XCTAssertEqual(result.date, date)
        XCTAssertEqual(result.dates, [date, date])
        XCTAssertEqual(result.url, url)
        XCTAssertEqual(result.urls, [url, url])
    }
    
    func testBoolWithDefaultStrategy() throws {
        let xml = """
        <root>\
        <test>1</test>\
        <tests><element>0</element><element>1</element><element>0</element></tests>\
        </root>
        """
        
        let result = try Test.decode(BoolStruct.self, from: xml)
        
        XCTAssertEqual(result.test, true)
        XCTAssertEqual(result.tests, [false, true, false])
    }
    
    func testBoolWithCustomStrategy() throws {
        let xml = """
        <root>\
        <test>yes</test>\
        <tests><element>no</element><element>yes</element><element>no</element></tests>\
        </root>
        """
        
        let document = try XMLDocument(xmlString: xml)
        let decoder = XMLDecoder()
        decoder.boolDecodingStrategy = XMLDecoder.BoolDecodingStrategy(falseValue: "no", trueValue: "yes")
        
        let result = try decoder.decode(BoolStruct.self, from: document)
        
        XCTAssertEqual(result.test, true)
        XCTAssertEqual(result.tests, [false, true, false])
    }
    
    func testBoolError() throws {
        let xml = """
        <root>\
        <test>1</test>\
        <tests><element>0</element><element>1</element><element>invalid</element></tests>\
        </root>
        """
        
        XCTAssertThrowsError(try Test.decode(BoolStruct.self, from: xml)) {
            error in
            guard let error = error as? DecodingError else {
                XCTFail("Unexpected error type.")
                return
            }
            switch error {
            case .typeMismatch(_, let context):
                XCTAssertEqual(context.codingPath.map { $0.stringValue }, ["tests", "[2]"])
                XCTAssertEqual(context.debugDescription, "Could not decode Bool.")
            default:
                XCTFail("Unexpected error value: \(error).")
            }
        }
    }
    
    func testData() throws {
        let xml = """
        <root>\
        <element>QgD/</element>\
        <elements><element>QgD/</element><element>QgD/</element></elements>\
        </root>
        """
        
        let result = try Test.decode(DataStruct.self, from: xml)
        
        let data = Data(bytes: [0x42, 0x00, 0xff])
        XCTAssertEqual(result.element, data)
        XCTAssertEqual(result.elements, [data, data])
    }
    
    func testSubclass() throws {
        let xml = """
        <root>\
        <base>base</base>\
        <sub>sub</sub>\
        </root>
        """
        
        let result = try Test.decode(Subclass.self, from: xml)
        
        XCTAssertEqual(result.base, "base")
        XCTAssertEqual(result.sub, "sub")
    }
    
    static var allTests = [
        ("testDecodeBasicXML", testDecodeBasicXML),
        ("testAttributes", testAttributes),
        ("testAttributesError", testAttributesError),
        ("testInlineText", testInlineText),
        ("testNamespaces", testNamespaces),
        ("testNamespacesErrorMissingNamespace", testNamespacesErrorMissingNamespace),
        ("testNamespacesErrorUnexpectedNamespace", testNamespacesErrorUnexpectedNamespace),
        ("testNamespacesWithOptions", testNamespacesWithOptions),
        ("testArrayWithKeyedStringElements", testArrayWithKeyedStringElements),
        ("testArrayWithKeyedStringElementsUnexpectedKeys", testArrayWithKeyedStringElementsUnexpectedKeys),
        ("testArrayWithAttributes", testArrayWithAttributes),
//        ("testArrayWithAlternatingKeysAndValues", testArrayWithAlternatingKeysAndValues),
        ("testArrayOfStructs", testArrayOfStructs),
        ("testArrayOfArrays", testArrayOfArrays),
        ("testNilAsMissing", testNilAsMissing),
        ("testNilAsEmpty", testNilAsEmpty),
        ("testFloatAndDouble", testFloatAndDouble),
        ("testDateAndURL", testDateAndURL),
        ("testBoolWithDefaultStrategy", testBoolWithDefaultStrategy),
        ("testBoolWithCustomStrategy", testBoolWithCustomStrategy),
        ("testBoolError", testBoolError),
        ("testData", testData),
        ("testSubclass", testSubclass),
    ]
}

