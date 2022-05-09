//
//  XMLCodableTestTypes.swift
//  XMLCoderTests
//
//  Created by Frank on 19/08/2019.
//

import XCTest
@testable import XMLCoder

// One Tag Tests

struct OneTagTestStruct: Codable {
    var tag: String
}

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

// Inline Text

struct ElementsWithInlineText: Codable {
    var inline0: String
    var stringElement: String
    var inline1: String
    var intElement: Int
    var inline2: Int
    
    private enum CodingKeys: String, CodingKey, XMLTypedKey {
        case inline0
        case stringElement
        case inline1
        case intElement
        case inline2
        
        var nodeType: XMLNodeType {
            switch self {
            case .inline0, .inline1, .inline2:
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
    var children: ChildArray
    
    struct ChildArray: Codable {
        var child: [String]
        
        private enum CodingKeys: String, CodingKey, XMLTypedKey {
            case child
            
            var nodeType: XMLNodeType {
                .array(nil)
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey, XMLTypedKey {
        case string
        case children
        
        var nodeType: XMLNodeType {
            .element
        }
    }
}

struct ArrayElementStruct: Codable {
    var id: String
    var inlineText: String
    
    private enum CodingKeys: String, CodingKey, XMLTypedKey {
        case id
        case inlineText
        
        var nodeType: XMLNodeType {
            switch self {
            case .id:
                return .attribute
            case .inlineText:
                return .inline
            }
        }
    }
}

struct AlternatingKeyElement: Codable {
    let value: String
    private enum CodingKeys: String, CodingKey, XMLTypedKey {
        case value
        var nodeType: XMLNodeType {
            return .inline
        }
    }
}
struct AlternatingValueElement: Codable {
    let type: String
    let value: String
    private enum CodingKeys: String, CodingKey, XMLTypedKey {
        case type
        case value
        var nodeType: XMLNodeType {
            switch self {
            case .type:
                return .attribute
            case .value:
                return .inline
            }
        }
    }
}
struct AlternatingArrayElement: Codable {
    let key: AlternatingKeyElement
    let value: AlternatingValueElement
}
struct AlternatingRoot: Codable { // TODO: conform encoder root to TypedKey, so that Root can be defined as [AlternatingArrayElement]
    let array: [AlternatingArrayElement]
    private enum CodingKeys: String, CodingKey, XMLTypedKey {
        case array
        var nodeType: XMLNodeType {
            .element
        }
    }
}

struct ArrayElement: Codable {
    let field1: String
    let field2: String
}

// Array elements as keys

struct ArrayFromElements: Codable, Equatable {
    var single: String
    var multiple: [String]
    
    private enum CodingKeys: String, CodingKey, XMLTypedKey {
        case single
        case multiple
        
        var nodeType: XMLNodeType {
            switch self {
            case .single:
                return .element
            case .multiple:
                return .array(nil)
            }
        }
    }
}

// Optionals

struct OptionalStruct: Codable {
    var optionalAttribute: String?
    var mandatoryAttribute: String
    var optionalElement: String?
    var mandatoryElement: String
    
    enum CodingKeys: CodingKey, XMLTypedKey {
        case optionalAttribute
        case mandatoryAttribute
        case optionalElement
        case mandatoryElement
        
        var nodeType: XMLNodeType {
            switch self {
            case .optionalAttribute, .mandatoryAttribute:
                return .attribute
            default:
                return .element
            }
        }
    }
}

// Float, Double

struct FloatDoubleStruct: Codable {
    var f: Float
    var d: Double
}

// Date, URL

struct DateURLStruct: Codable {
    var date: Date
    var dates: [Date]
    var url: URL
    var urls: [URL]
}

// Bool

struct BoolStruct: Codable {
    var test: Bool
    var tests: [Bool]
}

// Data

struct DataStruct: Codable {
    var element: Data
    var elements: [Data]
}

// Subclassing

class Base: Codable {
    var base: String = ""
}
class Subclass: Base {
    var sub: String = ""
    override init() {
        super.init()
    }
    private enum CodingKeys: String, CodingKey {
        case sub
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sub, forKey: .sub)
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sub = try container.decode(String.self, forKey: .sub)
        try super.init(from: decoder)
    }
}

