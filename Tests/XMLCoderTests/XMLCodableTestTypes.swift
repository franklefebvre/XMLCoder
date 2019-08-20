//
//  XMLCodableTestTypes.swift
//  XMLCoderTests
//
//  Created by Frank on 19/08/2019.
//

import XCTest
@testable import XMLCoder

// Basic tests

struct BasicTestStruct: Codable {
    var integer_element: Int
    var string_element: String
    var embedded_element: BasicEmbeddedStruct
    var string_array: [String]
    var int_array: [Int]
}

struct BasicEmbeddedStruct: Codable {
    var some_element: String
}

// Attributes tests

struct AttributesEnclosingStruct: Codable {
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

struct AttributesStruct: Codable {
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

// Namespaces

struct NamespaceStruct: Codable {
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

// Arrays

struct ArrayStruct: Codable {
    var string: String
    var children: [String]
    
    private enum CodingKeys: String, CodingKey, XMLTypedKey {
        case string
        case children
        
        var nodeType: XMLNodeType {
            switch self {
            case .children:
                return .array("child")
            default:
                return .element
            }
        }
    }
}

