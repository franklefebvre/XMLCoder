//
//  XMLEncoder.swift
//  XMLCoder
//
//  Created by Frank on 23/08/2018.
//  Copyright © 2018 Frank Lefebvre. All rights reserved.
//

import Foundation

open class XMLEncoder {
    
    /// The strategy to use for automatically changing the value of keys before encoding.
    public enum KeyEncodingStrategy {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys
        
        /// Convert from "camelCaseKeys" to "snake_case_keys" before writing a key to XML payload.
        ///
        /// Capital characters are determined by testing membership in `CharacterSet.uppercaseLetters` and `CharacterSet.lowercaseLetters` (Unicode General Categories Lu and Lt).
        /// The conversion to lower case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
        ///
        /// Converting from camel case to snake case:
        /// 1. Splits words at the boundary of lower-case to upper-case
        /// 2. Inserts `_` between words
        /// 3. Lowercases the entire string
        /// 4. Preserves starting and ending `_`.
        ///
        /// For example, `oneTwoThree` becomes `one_two_three`. `_oneTwoThree_` becomes `_one_two_three_`.
        ///
        /// - Note: Using a key encoding strategy has a nominal performance cost, as each string key has to be converted.
        case convertToSnakeCase
        
        /// Provide a custom conversion to the key in the encoded XML from the keys specified by the encoded types.
        /// The full path to the current encoding position is provided for context (in case you need to locate this key within the payload). The returned key is used in place of the last component in the coding path before encoding.
        /// If the result of the conversion is a duplicate key, then only one value will be present in the result.
        case custom((_ codingPath: [CodingKey]) -> CodingKey)
        
        fileprivate static func _convertToSnakeCase(_ stringKey: String) -> String {
            guard !stringKey.isEmpty else { return stringKey }
            
            var words : [Range<String.Index>] = []
            // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
            //
            // myProperty -> my_property
            // myURLProperty -> my_url_property
            //
            // We assume, per Swift naming conventions, that the first character of the key is lowercase.
            var wordStart = stringKey.startIndex
            var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex
            
            // Find next uppercase character
            while let upperCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
                let untilUpperCase = wordStart..<upperCaseRange.lowerBound
                words.append(untilUpperCase)
                
                // Find next lowercase character
                searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
                guard let lowerCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                    // There are no more lower case letters. Just end here.
                    wordStart = searchRange.lowerBound
                    break
                }
                
                // Is the next lowercase letter more than 1 after the uppercase? If so, we encountered a group of uppercase letters that we should treat as its own word
                let nextCharacterAfterCapital = stringKey.index(after: upperCaseRange.lowerBound)
                if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                    // The next character after capital is a lower case character and therefore not a word boundary.
                    // Continue searching for the next upper case for the boundary.
                    wordStart = upperCaseRange.lowerBound
                } else {
                    // There was a range of >1 capital letters. Turn those into a word, stopping at the capital before the lower case character.
                    let beforeLowerIndex = stringKey.index(before: lowerCaseRange.lowerBound)
                    words.append(upperCaseRange.lowerBound..<beforeLowerIndex)
                    
                    // Next word starts at the capital before the lowercase we just found
                    wordStart = beforeLowerIndex
                }
                searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
            }
            words.append(wordStart..<searchRange.upperBound)
            let result = words.map({ (range) in
                return stringKey[range].lowercased()
            }).joined(separator: "_")
            return result
        }
    }
    
    /// The strategy to use for encoding nil values in optional elements and attributes.
    public enum NilEncodingStrategy {
        /// Remove the attribute or element altogether. This is the default strategy.
        case missing
        /// Generate an empty element, or an attribute with an empty string.
        case empty
    }
    
    /// The strategy to use for encoding boolean values.
    public struct BoolEncodingStrategy {
        let falseValue: String
        let trueValue: String
    }

    /// The strategy to use for encoding keys. Defaults to `.useDefaultKeys`.
    open var keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys
    
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
    
    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    struct _Options {
        let keyEncodingStrategy: KeyEncodingStrategy
        let nilEncodingStrategy: NilEncodingStrategy
        let boolEncodingStrategy: BoolEncodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
        let defaultNamespace: String?
        let namespaceMap: [String: String]
        let namespacePrefix: String
    }
    
    /// The options set on the top-level encoder.
    var options: _Options {
        return _Options(keyEncodingStrategy: keyEncodingStrategy,
                        nilEncodingStrategy: nilEncodingStrategy,
                        boolEncodingStrategy: boolEncodingStrategy,
                        userInfo: userInfo,
                        defaultNamespace: defaultNamespace,
                        namespaceMap: namespaceMap,
                        namespacePrefix: namespacePrefix)
    }
    
    // MARK: - Constructing a XML Encoder
    
    /// Initializes `self` with default strategies.
    public init() {}
    
    // MARK: - Encoding Values
    
    /// Encodes the given top-level value and returns its XML representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the encoded XML data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    open func encode<T : Encodable>(_ value: T) throws -> XMLDocument {
        let namespaceProvider = XMLNamespaceProvider(defaultURI: self.options.defaultNamespace, initialMapping: self.options.namespaceMap, namePrefix: self.options.namespacePrefix)
        let encoder = _XMLEncoder(options: self.options, namespaceProvider: namespaceProvider)
        try value.encode(to: encoder)
        let element = encoder.topElement(withName: "root")
        element.addNamespaces(from: namespaceProvider)
        let document = XMLNode.document(withRootElement:element) as! XMLDocument
        return document
    }
}
