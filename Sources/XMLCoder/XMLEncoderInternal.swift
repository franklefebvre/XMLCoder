//
//  XMLEncoderInternal.swift
//  XMLCoder
//
//  Created by Frank on 23/08/2018.
//  Copyright © 2018 Frank Lefebvre. All rights reserved.
//

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

class _XMLEncoder: Encoder {
    
    init(options: XMLEncoder._Options, namespaceProvider: XMLNamespaceProvider) {
        self.options = options
        self.namespaceProvider = namespaceProvider
        self.rootStorage = RootXMLStorage()
    }
    
    let options: XMLEncoder._Options
    let namespaceProvider: XMLNamespaceProvider
    
    lazy var floatFormatter = newDecimalFormatter(16)
    lazy var doubleFormatter = newDecimalFormatter(128)
    lazy var dateFormatter = newDateFormatter()
    
    private func newDecimalFormatter(_ precision: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = precision
        return formatter
    }
    
    private func newDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .full
        formatter.timeStyle = .full
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:SS'Z'"
        return formatter
    }
    
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func topElement(withName name: String) -> XMLElement {
        return XMLNode.element(withName: name, children: rootStorage.nodes, attributes: rootStorage.attributes) as! XMLElement
    }
    
    var rootStorage: RootXMLStorage
    
    /// Returns whether a new element can be encoded at this coding path.
    ///
    /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
    fileprivate var canEncodeNewValue: Bool {
        // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
        // At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
        // If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
        //
        // This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
        // Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
        return self.rootStorage.count == self.codingPath.count
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let topElement: KeyedXMLElementStorage
        if canEncodeNewValue {
            topElement = KeyedXMLElementStorage()
            rootStorage.push(storage: topElement)
        }
        else {
            guard let last = rootStorage.last as? KeyedXMLElementStorage else {
                preconditionFailure("Top storage does not match expected KeyedXMLElementStorage.")
            }
            topElement = last
        }
        return KeyedEncodingContainer(XMLKeyedEncodingContainer(referencing: self, codingPath: codingPath, wrapping: topElement))
    }
    
    struct XMLKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        // MARK: Properties
        
        /// A reference to the encoder we're writing to.
        private let encoder: _XMLEncoder
        
        /// A reference to the container we're writing to.
        private var container: KeyedXMLElementStorage
        
        /// The path of coding keys taken to get to this point in encoding.
        private(set) public var codingPath: [CodingKey]
        
        // MARK: - Initialization
        
        /// Initializes `self` with the given references.
        fileprivate init(referencing encoder: _XMLEncoder, codingPath: [CodingKey], wrapping container: KeyedXMLElementStorage) {
            self.encoder = encoder
            self.codingPath = codingPath
            self.container = container
        }
        
        // MARK: - Coding Path Operations
        
        private func _converted(_ key: CodingKey) -> String {
            if let qualkey = key as? XMLQualifiedKey, let namespace = qualkey.namespace {
                if let name = encoder.namespaceProvider.name(for: namespace) {
                    // For now we'll move all namespace declarations up to the root level.
                    // TODO: add namespace URI to current storage, unless already declared in hierarchy.
                    return "\(name):\(convertedName(forKey: key))"
                }
            }
            return convertedName(forKey: key)
        }
        
        private func _nodeType(_ key: CodingKey) -> XMLNodeType {
            guard let typedKey = key as? XMLTypedKey else {
                return .element
            }
            return typedKey.nodeType
        }
        
        func convertedName(forKey key: CodingKey) -> String {
            let codingStrategy: XMLCoder.KeyCodingStrategy?
            switch _nodeType(key) {
            case .element, .array(_):
                codingStrategy = encoder.options.elementNameCodingStrategy
            case .attribute:
                codingStrategy = encoder.options.attributeNameCodingStrategy
            case .inline:
                codingStrategy = nil
            }
            return codingStrategy?.encodedName(for: codingPath + [key]) ?? key.stringValue
        }
        
        mutating func encodeNil(forKey key: Key) throws {
            if let element = self.encoder.xmlNilNode(withName: _converted(key), nodeType: _nodeType(key)) {
                self.container.append(node: element)
            }
        }
        
        mutating func encode(_ value: Bool, forKey key: Key) throws {
            let element = try self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        mutating func encode(_ value: Int, forKey key: Key) throws {
            let element = self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        mutating func encode(_ value: Int8, forKey key: Key) throws {
            let element = self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        mutating func encode(_ value: Int16, forKey key: Key) throws {
            let element = self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        mutating func encode(_ value: Int32, forKey key: Key) throws {
            let element = self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        mutating func encode(_ value: Int64, forKey key: Key) throws {
            let element = self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        mutating func encode(_ value: UInt, forKey key: Key) throws {
            let element = self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        mutating func encode(_ value: UInt8, forKey key: Key) throws {
            let element = self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        mutating func encode(_ value: UInt16, forKey key: Key) throws {
            let element = self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        mutating func encode(_ value: UInt32, forKey key: Key) throws {
            let element = self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        mutating func encode(_ value: UInt64, forKey key: Key) throws {
            let element = self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        mutating func encode(_ value: String, forKey key: Key) throws {
            let element = self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        // TODO: Float, Double, Date, Data
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            self.encoder.codingPath.append(key)
            defer {
                self.encoder.codingPath.removeLast()
            }
            let element = try self.encoder.xmlElement(value, withName: _converted(key), nodeType: _nodeType(key))
            self.container.append(node: element)
        }
        
        mutating func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
            try encodeIfPresent_(value, forKey: key)
        }
        
        mutating func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
            try encodeIfPresent_(value, forKey: key)
        }
        
        mutating func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
            try encodeIfPresent_(value, forKey: key)
        }
        
        mutating func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
            try encodeIfPresent_(value, forKey: key)
        }
        
        mutating func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
            try encodeIfPresent_(value, forKey: key)
        }
        
        mutating func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
            try encodeIfPresent_(value, forKey: key)
        }
        
        mutating func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
            try encodeIfPresent_(value, forKey: key)
        }
        
        mutating func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
            try encodeIfPresent_(value, forKey: key)
        }
        
        mutating func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
            try encodeIfPresent_(value, forKey: key)
        }
        
        mutating func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
            try encodeIfPresent_(value, forKey: key)
        }
        
        mutating func encodeIfPresent(_ value: String?, forKey key: Key) throws {
            try encodeIfPresent_(value, forKey: key)
        }
        
        // TODO: Float, Double, Date, Data
        
        mutating func encodeIfPresent_<T>(_ value: T?, forKey key: Key) throws where T : Encodable {
            if let value = value {
                try encode(value, forKey: key)
            }
            else {
                try encodeNil(forKey: key)
            }
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            fatalError()
        }
        
        mutating func superEncoder() -> Encoder {
            fatalError()
        }
        
        mutating func superEncoder(forKey key: Key) -> Encoder {
            fatalError()
        }
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let topElement: UnkeyedXMLElementStorage
        if canEncodeNewValue {
            topElement = UnkeyedXMLElementStorage()
            rootStorage.push(storage: topElement)
        }
        else {
            guard let last = rootStorage.last as? UnkeyedXMLElementStorage else {
                preconditionFailure("Top storage does not match expected UnkeyedXMLElementStorage.")
            }
            topElement = last
        }
        return XMLUnkeyedEncodingContainer(referencing: self, codingPath: codingPath, wrapping: topElement)
    }
    
    struct XMLUnkeyedEncodingContainer: UnkeyedEncodingContainer {
        
        struct IndexKey: CodingKey {
            var stringValue: String
            var intValue: Int?
            
            init?(stringValue: String) {
                self.stringValue = stringValue
                self.intValue = nil
            }
            
            init?(intValue: Int) {
                self.stringValue = "\(intValue)"
                self.intValue = intValue
            }
            
            init(index: Int) {
                self.stringValue = "[\(index)]"
                self.intValue = index
            }
        }
        
        // MARK: Properties
        
        /// A reference to the encoder we're writing to.
        private let encoder: _XMLEncoder
        
        /// A reference to the container we're writing to.
        private var container: UnkeyedXMLElementStorage
        
        /// The path of coding keys taken to get to this point in encoding.
        private(set) public var codingPath: [CodingKey]
        
        private let elementName: String?
        
        var count: Int { get { return container.nodes.count }}
        
        // MARK: - Initialization
        
        /// Initializes `self` with the given references.
        fileprivate init(referencing encoder: _XMLEncoder, codingPath: [CodingKey], wrapping container: UnkeyedXMLElementStorage) {
            self.encoder = encoder
            self.codingPath = codingPath
            self.container = container
            if let typedKey = codingPath.last as? XMLTypedKey {
                switch typedKey.nodeType {
                case .array(let elementName):
                    self.elementName = elementName
                default:
                    self.elementName = "element"
                }
            }
            else {
                self.elementName = "element"
            }
        }
        
        mutating func encodeNil() throws {
            self.encoder.codingPath.append(IndexKey(index: count))
            defer {
                self.encoder.codingPath.removeLast()
            }
            if encoder.options.nilEncodingStrategy == .empty {
                try encode("")
            }
        }
        
        mutating func encode(_ value: Bool) throws {
            self.encoder.codingPath.append(IndexKey(index: count))
            defer {
                self.encoder.codingPath.removeLast()
            }
            try encode(encoder.converted(value))
        }
        
        mutating func encode<T>(_ value: T) throws where T : Encodable {
            self.encoder.codingPath.append(IndexKey(index: count))
            defer {
                self.encoder.codingPath.removeLast()
            }
            if let elementName = elementName {
                let element = try self.encoder.xmlElement(value, withName: elementName)
                self.container.append(node: element)
            }
            else {
                let elements = try self.encoder.xmlElements(value)
                self.container.append(elements)
            }
        }
        
        mutating func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element : Encodable {
            fatalError()
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            fatalError()
        }
        
        mutating func superEncoder() -> Encoder {
            fatalError()
        }
        
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        if canEncodeNewValue {
            // TODO: implement
        }
        rootStorage.push(storage: SingleXMLElementStorage())
        return XMLSingleValueEncodingContainer(referencing: self, codingPath: codingPath, wrapping: rootStorage)
    }
    
    struct XMLSingleValueEncodingContainer: SingleValueEncodingContainer {
        
        // MARK: Properties
        
        /// A reference to the encoder we're writing to.
        private let encoder: _XMLEncoder
        
        /// A reference to the storage we're writing to.
        private var storage: RootXMLStorage
        
        /// The path of coding keys taken to get to this point in encoding.
        private(set) public var codingPath: [CodingKey]
        
        // MARK: - Initialization
        
        /// Initializes `self` with the given references.
        fileprivate init(referencing encoder: _XMLEncoder, codingPath: [CodingKey], wrapping storage: RootXMLStorage) {
            self.encoder = encoder
            self.codingPath = codingPath
            self.storage = storage
        }
        
        mutating func encodeNil() throws {
            if encoder.options.nilEncodingStrategy == .empty {
                try encode("")
            }
        }
        
        mutating func encode(_ value: Bool) throws {
            try encode(encoder.converted(value))
        }
        
        mutating func encode(_ value: String) throws {
            let element = XMLNode.text(withStringValue:value) as! XMLNode // box(value)
            self.storage.append(node: element)
        }
        
        mutating func encode(_ value: Double) throws {
            guard let formattedValue = encoder.doubleFormatter.string(for: value) else {
                return
            }
            try encode(formattedValue)
        }
        
        mutating func encode(_ value: Float) throws {
            guard let formattedValue = encoder.floatFormatter.string(for: value) else {
                return
            }
            try encode(formattedValue)
        }
        
        mutating func encode(_ value: Int) throws {
            try encode(String(value))
        }
        
        mutating func encode(_ value: Int8) throws {
            try encode(String(value))
        }
        
        mutating func encode(_ value: Int16) throws {
            try encode(String(value))
        }
        
        mutating func encode(_ value: Int32) throws {
            try encode(String(value))
        }
        
        mutating func encode(_ value: Int64) throws {
            try encode(String(value))
        }
        
        mutating func encode(_ value: UInt) throws {
            try encode(String(value))
        }
        
        mutating func encode(_ value: UInt8) throws {
            try encode(String(value))
        }
        
        mutating func encode(_ value: UInt16) throws {
            try encode(String(value))
        }
        
        mutating func encode(_ value: UInt32) throws {
            try encode(String(value))
        }
        
        mutating func encode(_ value: UInt64) throws {
            try encode(String(value))
        }
        
        mutating func encode<T>(_ value: T) throws where T : Encodable {
            fatalError()
        }
    }
    
    private func converted<T>(value: T) throws -> String? where T : Encodable & FixedWidthInteger {
        return value.description
    }
    
    private func converted<T>(value: T) throws -> String? where T : Encodable {
        if T.self == Date.self {
            return try converted(value as! Date)
        }
        else if T.self == URL.self {
            return converted(value as! URL)
        }
        else if T.self == Data.self {
            return try converted(value as! Data)
        }
        else if T.self == Bool.self {
            return converted(value as! Bool)
        }
        else {
            return nil
        }
    }
    
    private func converted(_ date: Date) throws -> String {
        switch options.dateEncodingStrategy {
        case .iso8601:
            return dateFormatter.string(from: date)
        case .formatted(let formatter):
            return formatter.string(from: date)
        case .custom(let closure):
            return try closure(self)
        }
    }
    
    private func converted(_ url: URL) -> String {
        return url.absoluteString
    }
    
    private func converted(_ data: Data) throws -> String {
        switch options.dataEncodingStrategy {
        case .base64:
            return data.base64EncodedString()
        case .hex(let uppercase):
            return data.hexEncodedString(uppercase: uppercase)
        case .custom(let closure):
            return try closure(self)
        }
    }
    
    private func converted(_ bool: Bool) -> String {
        return bool ? options.boolEncodingStrategy.trueValue : options.boolEncodingStrategy.falseValue
    }
}


extension _XMLEncoder {
    fileprivate func xmlNilNode(withName name: String, nodeType: XMLNodeType) -> XMLNode? {
        switch options.nilEncodingStrategy {
        case .missing:
            return nil
        case .empty:
            return xmlElement("", withName: name, nodeType: nodeType)
        }
    }
    
// TODO: compare performance between generics and direct implementation
//    fileprivate func xmlElement(_ value: Bool, withName name: String, nodeType: XMLNodeType = .element) -> XMLNode {
//        return xmlElement(converted(value), withName: name, nodeType: nodeType)
//    }
//    
    fileprivate func xmlElement(_ value: Int, withName name: String, nodeType: XMLNodeType = .element) -> XMLNode {
        return xmlElement(String(value), withName: name, nodeType: nodeType)
    }
    
    fileprivate func xmlElement(_ value: Int8, withName name: String, nodeType: XMLNodeType = .element) -> XMLNode {
        return xmlElement(String(value), withName: name, nodeType: nodeType)
    }
    
    fileprivate func xmlElement(_ value: Int16, withName name: String, nodeType: XMLNodeType = .element) -> XMLNode {
        return xmlElement(String(value), withName: name, nodeType: nodeType)
    }
    
    fileprivate func xmlElement(_ value: Int32, withName name: String, nodeType: XMLNodeType = .element) -> XMLNode {
        return xmlElement(String(value), withName: name, nodeType: nodeType)
    }
    
    fileprivate func xmlElement(_ value: Int64, withName name: String, nodeType: XMLNodeType = .element) -> XMLNode {
        return xmlElement(String(value), withName: name, nodeType: nodeType)
    }
    
    fileprivate func xmlElement(_ value: UInt, withName name: String, nodeType: XMLNodeType = .element) -> XMLNode {
        return xmlElement(String(value), withName: name, nodeType: nodeType)
    }
    
    fileprivate func xmlElement(_ value: UInt8, withName name: String, nodeType: XMLNodeType = .element) -> XMLNode {
        return xmlElement(String(value), withName: name, nodeType: nodeType)
    }
    
    fileprivate func xmlElement(_ value: UInt16, withName name: String, nodeType: XMLNodeType = .element) -> XMLNode {
        return xmlElement(String(value), withName: name, nodeType: nodeType)
    }
    
    fileprivate func xmlElement(_ value: UInt32, withName name: String, nodeType: XMLNodeType = .element) -> XMLNode {
        return xmlElement(String(value), withName: name, nodeType: nodeType)
    }
    
    fileprivate func xmlElement(_ value: UInt64, withName name: String, nodeType: XMLNodeType = .element) -> XMLNode {
        return xmlElement(String(value), withName: name, nodeType: nodeType)
    }
    
    fileprivate func xmlElement(_ value: String, withName name: String, nodeType: XMLNodeType = .element) -> XMLNode {
        switch nodeType {
        case .element, .array(_):
            return XMLNode.element(withName: name, stringValue: value) as! XMLNode
        case .attribute:
            return XMLNode.attribute(withName: name, stringValue: value) as! XMLNode
        case .inline:
            return XMLNode.text(withStringValue:value) as! XMLNode
        }
    }
    
    // TODO: Float, Double, Date, Data
    
    fileprivate func xmlElement<T>(_ value: T, withName name: String, nodeType: XMLNodeType = .element) throws -> XMLNode where T : Encodable {
        if let convertedValue = try converted(value: value) {
            return xmlElement(convertedValue, withName: name, nodeType: nodeType)
        }
        let depth = self.rootStorage.count
        do {
            try value.encode(to: self) // This should push a new container.
        }
        catch {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.rootStorage.count > depth {
                _ = self.rootStorage.pop()
            }
            throw error
        }
        // The top container should be a new container.
        // nodeType should be .element.
        guard self.rootStorage.count > depth else {
            return XMLNode.element(withName: name, children: nil, attributes: nil) as! XMLNode
        }
        let container = self.rootStorage.pop()
        return XMLNode.element(withName: name, children: container.nodes, attributes: container.attributes) as! XMLNode
    }
    
    fileprivate func xmlElements<T>(_ value: T) throws -> [XMLNode] where T : Encodable {
        let depth = self.rootStorage.count
        do {
            try value.encode(to: self) // This should push a new container.
        }
        catch {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.rootStorage.count > depth {
                _ = self.rootStorage.pop()
            }
            throw error
        }
        // The top container should be a new container.
        // nodeType should be .element.
        guard self.rootStorage.count > depth else {
            return []
        }
        let container = self.rootStorage.pop()
        // TODO: container.attributes MUST be empty --> throw if not.
        return container.nodes
    }
}
