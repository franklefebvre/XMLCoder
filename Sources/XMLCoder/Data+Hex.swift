//
//  Data+Hex.swift
//  XMLCoder
//
//  Created by Frank on 11/07/2020.
//

import Foundation

extension Data {
    init?(hexEncoded string: String) {
        guard string.count.isMultiple(of: 2) else { return nil }
        self.init()
        reserveCapacity(string.count / 2)
        var iter = string.makeIterator()
        while let c = iter.next() {
            guard let h = c.hexDigitValue, let l = iter.next()?.hexDigitValue else { return nil }
            let byte = h * 16 + l
            append(UInt8(byte))
        }
    }
    
    func hexEncodedString(uppercase: Bool) -> String {
        return self.map({ String(format: uppercase ? "%02X" : "%02x", $0) }).joined()
    }
}

