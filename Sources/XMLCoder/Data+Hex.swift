//
//  Data+Hex.swift
//  XMLCoder
//
//  Created by Frank on 11/07/2020.
//

import Foundation

extension Data {
    
    // see stackoverflow.com/questions/7520615/how-to-convert-an-nsdata-into-an-nsstring-hex-string
    
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
    
    func hexEncodedString() -> String {
        return self.map({ b in String(format: "%02X", b) }).joined()
    }
}

