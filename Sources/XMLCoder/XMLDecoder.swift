//
//  XMLDecoder.swift
//  XMLCoder
//
//  Created by Frank on 27/06/2019.
//  Copyright © 2019 Frank Lefebvre. All rights reserved.
//

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

open class XMLDecoder {
    // MARK: Options
    
    /// The strategy to use for decoding `Date` values.
    public enum DateDecodingStrategy {
        /// Defer to `Date` for decoding. This is the default strategy.
        case deferredToDate
        
        /// Decode the `Date` as a UNIX timestamp from a number.
        case secondsSince1970
        
        /// Decode the `Date` as UNIX millisecond timestamp from a number.
        case millisecondsSince1970
        
        /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
        case iso8601
        
        /// Decode the `Date` as a string parsed by the given formatter.
        case formatted(DateFormatter)
        
        /// Decode the `Date` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Date)
    }
    
    /// The strategy to use for decoding `Data` values.
    public enum DataDecodingStrategy {
        /// Defer to `Data` for decoding.
        case deferredToData
        
        /// Decode the `Data` from a Base64-encoded string. This is the default strategy.
        case base64
        
        /// Decode the `Data` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Data)
    }
    
    /// The strategy to use for non-JSON-conforming floating-point values (IEEE 754 infinity and NaN).
    public enum NonConformingFloatDecodingStrategy {
        /// Throw upon encountering non-conforming values. This is the default strategy.
        case `throw`
        
        /// Decode the values from the given representation strings.
        case convertFromString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
    
    /// The strategy to use for decoding optional elements and attributes.
    public enum NilDecodingStrategy {
        /// Decode missing attribute or element as nil. This is the default strategy.
        case missing
        /// Decode empty string as nil.
        case empty
    }
    
    /// The strategy to use for decoding boolean values.
    public struct BoolDecodingStrategy {
        let falseValue: String
        let trueValue: String
    }
    
    /// The strategy to use in decoding dates. Defaults to `.deferredToDate`.
    open var dateDecodingStrategy: DateDecodingStrategy = .deferredToDate
    
    /// The strategy to use in decoding binary data. Defaults to `.base64`.
    open var dataDecodingStrategy: DataDecodingStrategy = .base64
    
    /// The strategy to use in decoding non-conforming numbers. Defaults to `.throw`.
    open var nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy = .throw
    
    /// The strategy to use for reverse-encoding keys. Defaults to `.useDefaultKeys`.
    open var keyCodingStrategy: XMLCoder.KeyCodingStrategy = .useDefaultKeys
    
    /// The strategy to use for decoding optionals. Defaults to `.missing`.
    open var nilDecodingStrategy: NilDecodingStrategy = .missing
    
    /// The strategy to use for decoding boolean values. Defaults to `0|1`.
    open var boolDecodingStrategy = BoolDecodingStrategy(falseValue: "0", trueValue: "1")
    
    /// Contextual user-provided information for use during decoding.
    open var userInfo: [CodingUserInfoKey : Any] = [:]
    
    /// Namespace options
    open var defaultNamespace: String? = nil
    
    /// Document Root Tag
    open var documentRootTag: String? = nil
    
    /// Options set on the top-level encoder to pass down the decoding hierarchy.
    struct _Options {
        let dateDecodingStrategy: DateDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy
        let keyCodingStrategy: XMLCoder.KeyCodingStrategy
        let nilDecodingStrategy: NilDecodingStrategy
        let boolDecodingStrategy: BoolDecodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
        let defaultNamespace: String?
    }
    
    /// The options set on the top-level decoder.
    var options: _Options {
        return _Options(dateDecodingStrategy: dateDecodingStrategy,
                        dataDecodingStrategy: dataDecodingStrategy,
                        nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy,
                        keyCodingStrategy: keyCodingStrategy,
                        nilDecodingStrategy: nilDecodingStrategy,
                        boolDecodingStrategy: boolDecodingStrategy,
                        userInfo: userInfo,
                        defaultNamespace: defaultNamespace)
    }
    
    // MARK: - Constructing a XML Decoder
    
    /// Initializes `self` with default strategies.
    public init() {}
    
    // MARK: - Decoding Values
    
    /// Decodes a top-level value of the given type from the given XML document.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter document: The XML document to decode from.
    /// - returns: A value of the requested type.
    /// - throws: An error if any value throws an error during decoding.
    open func decode<T : Decodable>(_ type: T.Type, from document: XMLDocument) throws -> T {
        //let topLevel = XMLDecodingStorage(document: document)
        guard let topLevel = document.children?.first else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "Root node not found."))
        }
        if let documentRootTag = documentRootTag {
            guard let topLevelName = topLevel.name, topLevelName == documentRootTag else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "Unexpected root tag name."))
            }
        }
        let decoder = _XMLDecoder(referencing: document, options: self.options) // or topLevel?
        let nodeWrapper = XMLNodeWrapper(node: topLevel)
        guard let value = try decoder.unboxElement(nodeWrapper, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
        }
        
        return value
    }

}
