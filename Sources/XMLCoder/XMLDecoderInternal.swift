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
        // guard...
        // codingPath...
        let container = XMLKeyedDecodingContainer<Key>(referencing: self, codingPath: codingPath, wrapping: storage.topContainer)
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
        private var children: [String: XMLNode]
        
        /// The path of coding keys taken to get to this point in decoding.
        private(set) public var codingPath: [CodingKey]
        
        var allKeys: [Key]
        
        // MARK: - Initialization
        
        /// Initializes `self` with the given references.
        fileprivate init(referencing decoder: _XMLDecoder, codingPath: [CodingKey], wrapping container: XMLNode) {
            self.decoder = decoder
            self.codingPath = codingPath
            self.container = container
            self.allKeys = []
            var children = [String: XMLNode]()
            if let childNodes = container.children {
                for child in childNodes {
                    if let name = child.name {
                        children[name] = child
                    }
                }
            }
            self.children = children
        }
        
        // MARK: KeyedDecodingContainerProtocol Implementation
        
        func contains(_ key: Key) -> Bool {
            fatalError()
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            fatalError()
        }
        
        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            fatalError()
        }
        
        func decode(_ type: String.Type, forKey key: Key) throws -> String { // TODO: decodeStringElement, decodeStringAttribute
            guard let node = children[key.stringValue] else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key.stringValue)."))
            }
            return node.stringValue ?? ""
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
            guard let node = children[key.stringValue] else {
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
        
        /// A reference to the container we're reading from.
        private let container: XMLNode
        
        /// The path of coding keys taken to get to this point in decoding.
        var codingPath: [CodingKey]
        
        var currentIndex: Int
        
        // MARK: - Initialization
        
        /// Initializes `self` by referencing the given decoder and container.
        fileprivate init(referencing decoder: _XMLDecoder, wrapping container: XMLNode) {
            self.decoder = decoder
            self.container = container
            self.codingPath = decoder.codingPath
            self.currentIndex = 0
        }
        
        // MARK: - UnkeyedDecodingContainer Methods
        
        public var count: Int? {
            return self.container.childCount // TODO: filter children by type (element) and name (given in CodingKeys)
        }
        
        public var isAtEnd: Bool {
            return self.currentIndex >= self.count!
        }
        
        private func decodeStringAtCurrentIndex() throws -> String? {
            guard !self.isAtEnd else {
                throw DecodingError.valueNotFound(String.self, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Unkeyed container is at end."))
            }
            guard let node = self.container.child(at: self.currentIndex) else {
                throw DecodingError.valueNotFound(String.self, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Unkeyed container is at end."))
            }
            return node.stringValue
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
            guard let node = self.container.child(at: self.currentIndex) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Unkeyed container is at end."))
            }
            guard let value = try decoder.unboxElement(node, as: type) else {
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
        let node = self.storage.topContainer
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
    func unboxElement<T : Decodable>(_ value: XMLNode, as type: T.Type) throws -> T? {
        self.storage.push(node: value)
        defer { _ = self.storage.pop() }
        return try type.init(from: self)
    }
}
