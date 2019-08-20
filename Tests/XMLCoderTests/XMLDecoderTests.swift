import XCTest
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
        XCTAssertThrowsError(try Test.decode(AttributesEnclosingStruct.self, from: xml))
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
        XCTAssertThrowsError(try Test.decode(NamespaceStruct.self, from: xml))
    }
    
    func testNamespacesErrorUnexpectedNamespace() {
        let xml = """
        <root xmlns:ns1="http://some.url.example.com/whatever">\
        <ns1:with_namespace>test1</ns1:with_namespace>\
        <ns1:without_namespace>test2</ns1:without_namespace>\
        </root>
        """
        XCTAssertThrowsError(try Test.decode(NamespaceStruct.self, from: xml))
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
    
    static var allTests = [
        ("testDecodeBasicXML", testDecodeBasicXML),
        ("testAttributes", testAttributes),
        ("testAttributesError", testAttributesError),
        ("testNamespaces", testNamespaces),
        ("testNamespacesErrorMissingNamespace", testNamespacesErrorMissingNamespace),
        ("testNamespacesErrorUnexpectedNamespace", testNamespacesErrorUnexpectedNamespace),
        ("testNamespacesWithOptions", testNamespacesWithOptions),
        ("testArrayWithKeyedStringElements", testArrayWithKeyedStringElements),
        ("testArrayWithKeyedStringElementsUnexpectedKeys", testArrayWithKeyedStringElementsUnexpectedKeys),
    ]
}

