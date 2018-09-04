//
//  main.swift
//  XMLCoder
//
//  Created by Frank on 23/08/2018.
//  Copyright © 2018 Frank Lefebvre. All rights reserved.
//

import Foundation

print("Hello, World!")

struct TestStruct: Encodable {
    var integer_element: Int
    var string_element: String
    var embedded_element: EmbeddedStruct
    var string_array: [String]
    var int_array: [Int]
}

struct EmbeddedStruct: Encodable {
    var some_element: String
}

let embedded = EmbeddedStruct(some_element: "inside")
let value = TestStruct(integer_element: 42, string_element: "moof!", embedded_element: embedded, string_array: ["one", "two", "three"], int_array: [1, 2, 3])

let encoder = XMLEncoder()
let xml = try! encoder.encode(value)
let string = String(data: xml.xmlData, encoding: .utf8)

print(string!)

