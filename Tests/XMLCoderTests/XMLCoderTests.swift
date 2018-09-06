import XCTest
@testable import XMLCoder

final class XMLCoderTests: XCTestCase {
    func testExample() {
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
		let value = TestStruct(integer_element: 42, string_element: "moof!", embedded_element: embedded, string_array: ["one", "two", "three"], int_array: [1, 2, 3])

		let encoder = XMLEncoder()
		let xml = try! encoder.encode(value)
		let result = String(data: xml.xmlData, encoding: .utf8)
		
        let expected = """
        <root><integer_element>42</integer_element><string_element>moof!</string_element><embedded_element><some_element>inside</some_element></embedded_element><string_array><element>one</element><element>two</element><element>three</element></string_array><int_array><element>1</element><element>2</element><element>3</element></int_array></root>
        """
        
        XCTAssertEqual(result, expected)
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
