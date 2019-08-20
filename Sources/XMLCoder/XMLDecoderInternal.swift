//
//  XMLDecoderInternal.swift
//  XMLCoder
//
//  Created by Frank on 27/06/2019.
//  Copyright © 2019 Frank Lefebvre. All rights reserved.
//

import Foundation

class _XMLDecoder: Decoder {
    // MARK: Properties
    
    /// The decoder's storage.
    var storage: XMLDecodingStorage
    
    /// Options set on the top-level decoder.
    fileprivate let options: XMLDecoder._Options
    
    /// The path to the current point in encoding.
    fileprivate(set) public var codingPath: [CodingKey]
    
    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any] {
        return self.options.userInfo
    }
    
    // MARK: - Initialization
    
    /// Initializes `self` with the given top-level container and options.
    init(referencing container: XMLDocument, at codingPath: [CodingKey] = [], options: XMLDecoder._Options) {
        self.storage = XMLDecodingStorage()
        self.storage.push(node: container)
        self.codingPath = codingPath
        self.options = options
    }
    
    // MARK: - Decoder Methods
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard let element = storage.topContainer.node as? XMLElement else {
            fatalError() // TODO: throw
        }
        // codingPath...
        let container = XMLKeyedDecodingContainer<Key>(referencing: self, codingPath: codingPath, wrapping: element)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return XMLUnkeyedDecodingContainer(referencing: self, wrapping: storage.topContainer)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
    
    // MARK: Internal Containers
    
    struct XMLKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        // MARK: Properties
        
        /// A reference to the encoder we're reading from.
        private let decoder: _XMLDecoder
        
        /// A reference to the container we're reading from.
        private var container: XMLNode
        
        /// A shortcut for quick access to the container's children nodes by key.
        private var elements: [String: XMLNode]
        private var attributes: [String: XMLNode]
        private var textNodes: [XMLNode]
        
        /// The path of coding keys taken to get to this point in decoding.
        private(set) public var codingPath: [CodingKey]
        
        var allKeys: [Key]
        
        // MARK: - Initialization
        
        /// Initializes `self` with the given references.
        fileprivate init(referencing decoder: _XMLDecoder, codingPath: [CodingKey], wrapping container: XMLElement) {
            self.decoder = decoder
            self.codingPath = codingPath
            self.container = container
            self.allKeys = []
            var elements = [String: XMLNode]()
            var attributes = [String: XMLNode]()
            var textNodes = [XMLNode]()
            for child in container.children ?? [] {
                switch child.kind {
                case .element:
                    if let localName = child.localName {
                        let qualifiedName: String
                        if let namespace = child.uri {
                            qualifiedName = "\(namespace):\(localName)"
                        }
                        else {
                            qualifiedName = localName
                        }
                        elements[qualifiedName] = child
                    }
                case .attribute:
                    if let name = child.name {
                        attributes[name] = child
                    }
                case .text:
                    textNodes.append(child)
                default:
                    break
                }
            }
            for attribute in container.attributes ?? [] {
                if let name = attribute.name {
                    attributes[name] = attribute
                }
            }
            self.elements = elements
            self.attributes = attributes
            self.textNodes = textNodes
        }
        
        // MARK: - Coding Path Operations
        
        private func _nodeType(_ key: CodingKey) -> XMLNodeType {
            guard let typedKey = key as? XMLTypedKey else {
                return .element
            }
            return typedKey.nodeType
        }
        
        // MARK: KeyedDecodingContainerProtocol Implementation
        
        func contains(_ key: Key) -> Bool {
            fatalError()
        }
        
        func qualifiedName(forKey key: CodingKey) -> String {
            let localName = key.stringValue
            if let qualifiedKey = key as? XMLQualifiedKey, let namespace = qualifiedKey.namespace {
                return "\(namespace):\(localName)"
            }
            if let namespace = self.decoder.options.defaultNamespace {
                return "\(namespace):\(localName)"
            }
            return localName
        }
        
        func node(forKey key: Key) -> XMLNodeWrapper? {
            switch _nodeType(key) {
            case .element:
                let qualifiedKey = qualifiedName(forKey: key)
                guard let node = elements[qualifiedKey] else {
                    return nil
                }
                return XMLNodeWrapper(node: node, elementName: nil)
            case .attribute:
                guard let node = attributes[key.stringValue] else {
                    return nil
                }
                return XMLNodeWrapper(node: node, elementName: nil)
            case .inline:
                guard let node = textNodes.first else { // TODO: use index
                    return nil
                }
                return XMLNodeWrapper(node: node, elementName: nil)
            case .array(let elementName):
                let qualifiedKey = qualifiedName(forKey: key)
                guard let node = elements[qualifiedKey] else {
                    return nil
                }
                return XMLNodeWrapper(node: node, elementName: elementName)
            }
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            fatalError()
        }
        
        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            fatalError()
        }
        
        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            guard let nodeWrapper = node(forKey: key) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key.stringValue)."))
            }
            return nodeWrapper.node.stringValue ?? ""
        }
        
        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            fatalError()
        }
        
        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            fatalError()
        }
        
        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            let string = try decode(String.self, forKey: key)
            guard let value = Int(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            return value
        }
        
        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            let string = try decode(String.self, forKey: key)
            guard let value = Int8(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            return value
        }
        
        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            let string = try decode(String.self, forKey: key)
            guard let value = Int16(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            return value
        }
        
        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            let string = try decode(String.self, forKey: key)
            guard let value = Int32(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            return value
        }
        
        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            let string = try decode(String.self, forKey: key)
            guard let value = Int64(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            return value
        }
        
        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            let string = try decode(String.self, forKey: key)
            guard let value = UInt(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            return value
        }
        
        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            let string = try decode(String.self, forKey: key)
            guard let value = UInt8(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            return value
        }
        
        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            let string = try decode(String.self, forKey: key)
            guard let value = UInt16(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            return value
        }
        
        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            let string = try decode(String.self, forKey: key)
            guard let value = UInt32(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            return value
        }
        
        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            let string = try decode(String.self, forKey: key)
            guard let value = UInt64(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            return value
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            guard let node = node(forKey: key) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key.stringValue)."))
            }
            guard let value = try decoder.unboxElement(node, as: type) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            return value
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            fatalError()
        }
        
        func superDecoder() throws -> Decoder {
            fatalError()
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            fatalError()
        }
    }
    
    struct XMLUnkeyedDecodingContainer: UnkeyedDecodingContainer {
        // MARK: Properties
        
        /// A reference to the decoder we're reading from.
        private let decoder: _XMLDecoder
        
        /// The container's filtered children nodes.
        private var elements: [XMLNode]
        
        /// The path of coding keys taken to get to this point in decoding.
        var codingPath: [CodingKey]
        
        var currentIndex: Int
        
        // MARK: - Initialization
        
        /// Initializes `self` by referencing the given decoder and container.
        fileprivate init(referencing decoder: _XMLDecoder, wrapping container: XMLNodeWrapper) {
            self.decoder = decoder
            self.codingPath = decoder.codingPath
            self.currentIndex = 0
            let elementName = container.elementName ?? "element" // TODO: default value in decoder options
            if let children = container.node.children {
                self.elements = children.filter {
                    node in
                    guard let name = node.name else {
                        return false
                    }
                    return name == elementName
                }
            }
            else {
                self.elements = []
            }
        }
        
        // MARK: - UnkeyedDecodingContainer Methods
        
        public var count: Int? {
            return self.elements.count
        }
        
        public var isAtEnd: Bool {
            return self.currentIndex >= self.count!
        }
        
        private func decodeStringAtCurrentIndex() throws -> String? {
            guard !self.isAtEnd else {
                throw DecodingError.valueNotFound(String.self, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Unkeyed container is at end."))
            }
            return self.elements[currentIndex].stringValue
        }
        
        mutating func decodeNil() throws -> Bool {
            fatalError()
        }
        
        mutating func decode(_ type: Bool.Type) throws -> Bool {
            fatalError()
        }
        
        mutating func decode(_ type: String.Type) throws -> String {
            let decoded = try self.decodeStringAtCurrentIndex() ?? ""
            self.currentIndex += 1
            return decoded
        }
        
        mutating func decode(_ type: Double.Type) throws -> Double {
            fatalError()
        }
        
        mutating func decode(_ type: Float.Type) throws -> Float {
            fatalError()
        }
        
        mutating func decode(_ type: Int.Type) throws -> Int {
            guard let string = try self.decodeStringAtCurrentIndex() else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) but found empty node instead."))
            }
            guard let value = Int(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            self.currentIndex += 1
            return value
        }
        
        mutating func decode(_ type: Int8.Type) throws -> Int8 {
            guard let string = try self.decodeStringAtCurrentIndex() else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) but found empty node instead."))
            }
            guard let value = Int8(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            self.currentIndex += 1
            return value
        }
        
        mutating func decode(_ type: Int16.Type) throws -> Int16 {
            guard let string = try self.decodeStringAtCurrentIndex() else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) but found empty node instead."))
            }
            guard let value = Int16(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            self.currentIndex += 1
            return value
        }
        
        mutating func decode(_ type: Int32.Type) throws -> Int32 {
            guard let string = try self.decodeStringAtCurrentIndex() else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) but found empty node instead."))
            }
            guard let value = Int32(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            self.currentIndex += 1
            return value
        }
        
        mutating func decode(_ type: Int64.Type) throws -> Int64 {
            guard let string = try self.decodeStringAtCurrentIndex() else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) but found empty node instead."))
            }
            guard let value = Int64(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            self.currentIndex += 1
            return value
        }
        
        mutating func decode(_ type: UInt.Type) throws -> UInt {
            guard let string = try self.decodeStringAtCurrentIndex() else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) but found empty node instead."))
            }
            guard let value = UInt(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            self.currentIndex += 1
            return value
        }
        
        mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
            guard let string = try self.decodeStringAtCurrentIndex() else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) but found empty node instead."))
            }
            guard let value = UInt8(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            self.currentIndex += 1
            return value
        }
        
        mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
            guard let string = try self.decodeStringAtCurrentIndex() else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) but found empty node instead."))
            }
            guard let value = UInt16(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            self.currentIndex += 1
            return value
        }
        
        mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
            guard let string = try self.decodeStringAtCurrentIndex() else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) but found empty node instead."))
            }
            guard let value = UInt32(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            self.currentIndex += 1
            return value
        }
        
        mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
            guard let string = try self.decodeStringAtCurrentIndex() else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) but found empty node instead."))
            }
            guard let value = UInt64(string) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Could not decode \(type)."))
            }
            self.currentIndex += 1
            return value
        }
        
        mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            guard !self.isAtEnd else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Unkeyed container is at end."))
            }
            let node = self.elements[self.currentIndex]
            let nodeWrapper = XMLNodeWrapper(node: node, elementName: nil)
            guard let value = try decoder.unboxElement(nodeWrapper, as: type) else {
                fatalError()
            }
            self.currentIndex += 1
            return value
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            fatalError()
        }
        
        mutating func superDecoder() throws -> Decoder {
            fatalError()
        }
    }
}

extension _XMLDecoder: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        fatalError()
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        fatalError()
    }
    
    func decode(_ type: String.Type) throws -> String {
        let node = self.storage.topContainer.node
        return node.stringValue ?? ""
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        fatalError()
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        fatalError()
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        let string = try self.decode(String.self)
        guard let value = Int(string) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not decode \(type)."))
        }
        return value
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        let string = try self.decode(String.self)
        guard let value = Int8(string) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not decode \(type)."))
        }
        return value
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        let string = try self.decode(String.self)
        guard let value = Int16(string) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not decode \(type)."))
        }
        return value
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        let string = try self.decode(String.self)
        guard let value = Int32(string) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not decode \(type)."))
        }
        return value
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        let string = try self.decode(String.self)
        guard let value = Int64(string) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not decode \(type)."))
        }
        return value
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        let string = try self.decode(String.self)
        guard let value = UInt(string) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not decode \(type)."))
        }
        return value
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        let string = try self.decode(String.self)
        guard let value = UInt8(string) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not decode \(type)."))
        }
        return value
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        let string = try self.decode(String.self)
        guard let value = UInt16(string) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not decode \(type)."))
        }
        return value
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        let string = try self.decode(String.self)
        guard let value = UInt32(string) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not decode \(type)."))
        }
        return value
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        let string = try self.decode(String.self)
        guard let value = UInt64(string) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not decode \(type)."))
        }
        return value
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try self.unboxElement(self.storage.topContainer, as: type)!
    }
}

extension _XMLDecoder {
    func unboxElement<T : Decodable>(_ value: XMLNodeWrapper, as type: T.Type) throws -> T? {
        self.storage.push(value)
        defer { _ = self.storage.pop() }
        return try type.init(from: self)
    }
}
