//
//  XMLTestsCommon.swift
//  XMLCoderTests
//
//  Created by Frank on 11/09/2018.
//

import Foundation
@testable import XMLCoder

extension String {
    func substringWithXMLTag(_ tag: String) -> Substring? {
        let start = "<\(tag)"
        let end = "</\(tag)>"
        guard let startRange = self.range(of: start) else { return nil }
        guard let endRange = self.range(of: end) else { return nil }
        return self[startRange.lowerBound..<endRange.upperBound]
    }
}

struct Test {
    static func xmlString<T: Encodable>(_ value: T) -> String {
        let encoder = XMLEncoder()
        let xml = try! encoder.encode(value)
        let result = String(data: xml.xmlData, encoding: .utf8)!
        return result
    }

    static func jsonString<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let json = try! encoder.encode(value)
        let result = String(data: json, encoding: .utf8)!
        return result
    }
}
