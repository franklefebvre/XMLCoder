//
//  XMLCoder.swift
//  XMLCoder
//
//  Created by Frank on 06/06/2020.
//

import Foundation

public enum XMLCoder {
    
    /// The strategy to use for automatically changing the value of keys before encoding.
    public enum KeyCodingStrategy {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys
        
        /// Provide a custom conversion to the key in the encoded XML from the keys specified by the encoded types.
        /// The full path to the current encoding position is provided for context (in case you need to locate this key within the payload). The returned key is used in place of the last component in the coding path before encoding.
        /// If the result of the conversion is a duplicate key, then only one value will be present in the result.
        case custom((_ codingPath: [CodingKey]) -> String)
    }
}

extension XMLCoder.KeyCodingStrategy {
    func encodedName(for codingPath: [CodingKey]) -> String? {
        switch self {
        case .useDefaultKeys:
            return codingPath.last?.stringValue
        case .custom(let transform):
            return transform(codingPath)
        }
    }
}
