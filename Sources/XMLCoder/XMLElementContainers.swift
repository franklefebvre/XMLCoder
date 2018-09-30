//
//  XMLElementContainers.swift
//  XMLCoder
//
//  Created by Frank on 24/08/2018.
//  Copyright © 2018 Frank Lefebvre. All rights reserved.
//

import Foundation

enum XMLElementMode {
    case inline
    case keyed(String)
}

protocol XMLCustomElementMode {
    var elementMode: XMLElementMode { get }
}

typealias XMLStringElement = String
extension XMLStringElement: XMLCustomElementMode {
    var elementMode: XMLElementMode {
        return .keyed("element")
    }
}

typealias XMLIntElement = Int
extension XMLIntElement: XMLCustomElementMode {
    var elementMode: XMLElementMode {
        return .keyed("element")
    }
}

protocol XMLEncodingContainer {
    var nodes: [XMLNode] { get }
    var attributes: [XMLNode] { get }
    var elementMode: XMLElementMode { get }
}

class UnkeyedXMLElementContainer: XMLEncodingContainer {
    var nodes: [XMLNode] = []
    var attributes: [XMLNode] = []
    var elementMode: XMLElementMode = .keyed("element")
}

class KeyedXMLElementContainer: XMLEncodingContainer {
    var nodes: [XMLNode] = []
    var attributes: [XMLNode] = []
    var elementMode: XMLElementMode = .inline
}

class SingleXMLElementContainer: XMLEncodingContainer {
    var nodes: [XMLNode] = []
    var attributes: [XMLNode] = []
    var elementMode: XMLElementMode = .inline
}

struct CodableXMLString<T>: Encodable, ExpressibleByStringLiteral {
    typealias StringLiteralType = String
    
    let value: String
    
    init(stringLiteral: StringLiteralType) {
        self.value = stringLiteral
    }
}

enum InlineTextType {}
enum AttributeType {}

typealias CodableXMLInlineText = CodableXMLString<InlineTextType>
typealias CodableXMLAttribute = CodableXMLString<AttributeType>

protocol XMLQualifiedKey {
    var namespace: String? { get }
}

protocol XMLArrayKey {
    static var elementName: String { get }
}

struct XMLArrayElement<K: XMLArrayKey>: ExpressibleByStringLiteral, Encodable {
    var value: String
    init(stringLiteral: StringLiteralType) {
        self.value = stringLiteral
    }
    
    private struct CodingKeys: CodingKey {
        var stringValue: String
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int? {
            return nil
        }
        
        init?(intValue: Int) {
            return nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        let key = CodingKeys(stringValue: K.elementName)!
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: key)
    }
}

