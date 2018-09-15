//
//  XMLTests.swift
//  XMLCoder
//
//  Created by Frank on 11/09/2018.
//

import XCTest
@testable import XMLCoder

final class XMLTests: XCTestCase {
    func testWhitespace() throws {
        let initialString = """
        <whitespace xml:space="preserve">   a   b   c
        d   e   f   </whitespace>
        """
        let xml = try XMLDocument(xmlString: initialString)
        let finalString = String(data: xml.xmlData, encoding: .utf8)
        XCTAssertEqual(initialString.substringWithXMLTag("whitespace"), finalString?.substringWithXMLTag("whitespace"))
    }
    
    func testCreateNamespaces() {
        let element = XMLNode.element(withName: "element") as! XMLElement
        let defaultNamespace = XMLNode.namespace(withName: "", stringValue: "http://namespace.example.com/ns/default") as! XMLNode
        let namespace = XMLNode.namespace(withName: "ns1", stringValue: "http://namespace.example.com/ns/1") as! XMLNode
        element.namespaces = [defaultNamespace, namespace]
        let embedded = XMLNode.element(withName: "ns1:embedded") as! XMLElement
        element.addChild(embedded)
        let xml = XMLDocument(rootElement: element)
        let finalString = String(data: xml.xmlData, encoding: .utf8)
        
        let expectedString = """
        <element xmlns="http://namespace.example.com/ns/default" xmlns:ns1="http://namespace.example.com/ns/1">\
        <ns1:embedded></ns1:embedded>\
        </element>
        """
        
        XCTAssertEqual(expectedString.substringWithXMLTag("element"), finalString?.substringWithXMLTag("element"))
    }
    
    func testParseNamespaces() throws {
        let initialString = """
        <element xmlns="http://namespace.example.com/ns/default" xmlns:ns1="http://namespace.example.com/ns/1">\
        <ns1:embedded></ns1:embedded>\
        <default></default>\
        </element>
        """
        let xml = try XMLDocument(xmlString: initialString)
        let rootElement = xml.rootElement()
        let rootNamespaces = rootElement?.namespaces ?? []
        XCTAssertEqual(rootNamespaces.count, 2)
        let ns0 = rootNamespaces[0]
        XCTAssertEqual(ns0.name, "")
        XCTAssertEqual(ns0.stringValue, "http://namespace.example.com/ns/default")
        let ns1 = rootNamespaces[1]
        XCTAssertEqual(ns1.name, "ns1")
        XCTAssertEqual(ns1.stringValue, "http://namespace.example.com/ns/1")
    }
    
    static var allTests = [
        ("testWhitespace", testWhitespace),
        ("testCreateNamespaces", testCreateNamespaces),
        ("testParseNamespaces", testParseNamespaces),
    ]
}
