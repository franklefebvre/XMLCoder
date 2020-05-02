//
//  CombineSupportTests.swift
//  
//
//  Created by frank on 02/05/2020.
//

import XCTest

#if canImport(Combine)

import Combine
import Foundation
@testable import XMLCoder

final class CombineSupportTests: XCTestCase {
    func testCombineEncode() {
        if #available(OSX 10.15, *) {
            let value = OneTagTestStruct(tag: "value")
            let encoder = XMLEncoder(documentRootTag: "root")
            
            let expect = expectation(description: "publisher did finish")
            var subscriptions = Set<AnyCancellable>()
            Just(value)
                .encode(encoder: encoder)
                .map {
                    String(data: $0.xmlData, encoding: .utf8)!
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expect.fulfill()
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }) { result in
                let expected = """
                <root><tag>value</tag></root>
                """
                XCTAssertEqual(result.substringWithXMLTag("root"), expected.substringWithXMLTag("root"))
            }
            .store(in: &subscriptions)
            waitForExpectations(timeout: 1)
        }
    }
    
    func testCombineDecode() {
        if #available(OSX 10.15, *) {
            let xml = """
            <root>\
            <tag>value</tag>\
            </root>
            """
            let decoder = XMLDecoder()
            let expect = expectation(description: "publisher did finish")
            var subscriptions = Set<AnyCancellable>()
            Just(xml)
                .tryMap {
                    try XMLDocument(xmlString: $0)
            }
            .decode(type: OneTagTestStruct.self, decoder: decoder)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expect.fulfill()
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }) { result in
                XCTAssertEqual(result.tag, "value")
            }
            .store(in: &subscriptions)
            waitForExpectations(timeout: 1)
        }
    }
    
    static var allTests = [
        ("testCombineEncode", testCombineEncode),
        ("testCombineDecode", testCombineDecode),
    ]
}

#else

final class CombineSupportTests: XCTestCase {
    static var allTests = [(String, (CombineSupportTests) -> () -> ())]()
}

#endif

