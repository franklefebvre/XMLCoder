//
//  XMLTestsCommon.swift
//  XMLCoderTests
//
//  Created by Frank on 11/09/2018.
//

import Foundation

extension String {
    func substringWithXMLTag(_ tag: String) -> Substring? {
        let start = "<\(tag)"
        let end = "</\(tag)>"
        guard let startRange = self.range(of: start) else { return nil }
        guard let endRange = self.range(of: end) else { return nil }
        return self[startRange.lowerBound..<endRange.upperBound]
    }
}
