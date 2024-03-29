//
//  XMLEncoder.swift
//  XMLCoder
//
//  Created by Frank on 23/08/2018.
//  Copyright © 2018 Frank Lefebvre. All rights reserved.
//

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

open class XMLEncoder {
    // MARK: Options
    
    /// The strategy to use for encoding `Date` values.
    public enum DateEncodingStrategy {
        /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format). This is the default strategy.
        case iso8601
        
        /// Encode the `Date` as a string generated by the given formatter.
        case formatted(DateFormatter)
        
        /// Encode the `Date` as a custom value encoded by the given closure.
        case custom((_ encoder: Encoder) throws -> String)
    }
    
    /// The strategy to use for encoding `Data` values.
    public enum DataEncodingStrategy {
        /// Encode the `Data` to a Base64-encoded string. This is the default strategy.
        case base64
        
        /// Encode the `Data` to a hex-encoded string.
        case hex(uppercase: Bool)
        
        /// Encode the `Data` as a custom value encoded by the given closure.
        case custom((_ encoder: Encoder) throws -> String)
    }
    
    /// The strategy to use for encoding nil values in optional elements and attributes.
    public enum NilEncodingStrategy {
        /// Remove the attribute or element altogether. This is the default strategy.
        case missing
        /// Generate an empty element, or an attribute with an empty string.
        case empty
    }
    
    /// The strategy to use for encoding boolean values.
    // TODO: enum (constants, custom)
    public struct BoolEncodingStrategy {
        let falseValue: String
        let trueValue: String
    }

    /// The strategy to use for encoding dates. Defaults to `.iso8601`.
    open var dateEncodingStrategy: DateEncodingStrategy = .iso8601
    
    /// The strategy to use for encoding binary data. Defaults to `.base64`.
    open var dataEncodingStrategy: DataEncodingStrategy = .base64
    
    /// The strategy to use for encoding keys. Defaults to `.useDefaultKeys`.
    open var keyCodingStrategy: XMLCoder.KeyCodingStrategy = .useDefaultKeys
    
    /// The strategy to use for encoding XML element names. Defaults to setting defined by `keyCodingStrategy`.
    open var elementNameCodingStrategy: XMLCoder.KeyCodingStrategy? = nil
    
    /// The strategy to use for encoding XML attribute names. Defaults to setting defined by `keyCodingStrategy`.
    open var attributeNameCodingStrategy: XMLCoder.KeyCodingStrategy? = nil
    
    /// The strategy to use for encoding nil optionals. Defaults to `.missing`.
    open var nilEncodingStrategy: NilEncodingStrategy = .missing
    
    /// The strategy to use for encoding boolean values. Defaults to `0|1`.
    open var boolEncodingStrategy = BoolEncodingStrategy(falseValue: "0", trueValue: "1")
    
    /// Contextual user-provided information for use during encoding.
    open var userInfo: [CodingUserInfoKey : Any] = [:]
    
    /// Namespace options
    open var defaultNamespace: String? = nil
    open var namespaceMap: [String: String] = [:]
    open var namespacePrefix: String = "ns"
    
    /// Document Root Tag
    open var documentRootTag: String
    
    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    struct _Options {
        let dateEncodingStrategy: DateEncodingStrategy
        let dataEncodingStrategy: DataEncodingStrategy
        let elementNameCodingStrategy: XMLCoder.KeyCodingStrategy
        let attributeNameCodingStrategy: XMLCoder.KeyCodingStrategy
        let nilEncodingStrategy: NilEncodingStrategy
        let boolEncodingStrategy: BoolEncodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
        let defaultNamespace: String?
        let namespaceMap: [String: String]
        let namespacePrefix: String
    }
    
    /// The options set on the top-level encoder.
    var options: _Options {
        return _Options(dateEncodingStrategy: dateEncodingStrategy,
                        dataEncodingStrategy: dataEncodingStrategy,
                        elementNameCodingStrategy: elementNameCodingStrategy ?? keyCodingStrategy,
                        attributeNameCodingStrategy: attributeNameCodingStrategy ?? keyCodingStrategy,
                        nilEncodingStrategy: nilEncodingStrategy,
                        boolEncodingStrategy: boolEncodingStrategy,
                        userInfo: userInfo,
                        defaultNamespace: defaultNamespace,
                        namespaceMap: namespaceMap,
                        namespacePrefix: namespacePrefix)
    }
    
    // MARK: - Constructing a XML Encoder
    
    /// Initializes `self` with default strategies.
    public init(documentRootTag: String) {
        self.documentRootTag = documentRootTag
    }
    
    // MARK: - Encoding Values
    
    /// Encodes the given top-level value and returns its XML representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `XMLDocument` value containing the encoded XML DOM.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    open func encode<T : Encodable>(_ value: T) throws -> XMLDocument {
        let namespaceProvider = XMLNamespaceProvider(defaultURI: self.options.defaultNamespace, initialMapping: self.options.namespaceMap, namePrefix: self.options.namespacePrefix)
        let encoder = _XMLEncoder(options: self.options, namespaceProvider: namespaceProvider)
        try value.encode(to: encoder)
        let element = encoder.topElement(withName: documentRootTag)
        element.addNamespaces(from: namespaceProvider)
        let document = XMLNode.document(withRootElement:element) as! XMLDocument
        return document
    }
}
