//
//  XMLElementStorage.swift
//  XMLCoder
//
//  Created by Frank on 24/08/2018.
//  Copyright © 2018 Frank Lefebvre. All rights reserved.
//

import Foundation
#if os(Linux)
import FoundationXML
#endif

public enum XMLNodeType {
    case element
    case attribute
    case inline
    case array(String?)
}

protocol XMLEncodingStorage {
    var nodes: [XMLNode] { get }
    var attributes: [XMLNode] { get }
    
    func append(node: XMLNode)
    func append(attribute: XMLNode)
}

// TODO: reimplement as structs after recursion has been gotten rid of

class UnkeyedXMLElementStorage: XMLEncodingStorage {
    var nodes: [XMLNode] = []
    var attributes: [XMLNode] = []
    
    func append(node: XMLNode) {
        if node.kind == .attribute {
            attributes.append(node)
        }
        else {
            nodes.append(node)
        }
    }
    
    func append(_ elements: [XMLNode]) {
        nodes.append(contentsOf: elements)
    }
    
    func append(attribute: XMLNode) { // TODO: remove
        attributes.append(attribute)
    }
}

class KeyedXMLElementStorage: XMLEncodingStorage {
    var nodes: [XMLNode] = []
    var attributes: [XMLNode] = []
    
    func append(node: XMLNode) {
        if node.kind == .attribute {
            attributes.append(node)
        }
        else {
            nodes.append(node)
        }
    }
    
    func append(attribute: XMLNode) { // TODO: remove
        attributes.append(attribute)
    }
}

class SingleXMLElementStorage: XMLEncodingStorage {
    var nodes: [XMLNode] = []
    var attributes: [XMLNode] = []
    
    func append(node: XMLNode) {
        if node.kind == .attribute {
            attributes.append(node)
        }
        else {
            nodes.append(node)
        }
    }
    
    func append(attribute: XMLNode) { // TODO: remove
        attributes.append(attribute)
    }
}

class RootXMLStorage: XMLEncodingStorage {
    private var stack: [XMLEncodingStorage] = []
    
    var count: Int {
        return stack.count
    }
    
    var last: XMLEncodingStorage {
        guard let last = stack.last else {
            fatalError()
        }
        return last
    }
    
    var nodes: [XMLNode] {
        return stack.last!.nodes
    }
    var attributes: [XMLNode] {
        return stack.last!.attributes
    }
    
    func append(node: XMLNode) {
        stack.last!.append(node: node)
    }
    
    func append(attribute: XMLNode) {
        stack.last!.append(attribute: attribute)
    }
    
    func push(storage: XMLEncodingStorage) {
        stack.append(storage)
    }
    
    func pop() -> XMLEncodingStorage {
        return stack.removeLast()
    }
}

public protocol XMLQualifiedKey {
    var namespace: String? { get }
}

public protocol XMLTypedKey {
    var nodeType: XMLNodeType { get }
}

public protocol XMLArrayKey {
    static var elementName: String { get }
}

// MARK: Decoding

struct XMLNodeWrapper {
    let node: XMLNode
    let elementName: String?
    var currentTextNodeIndex: Int
    
    init(node: XMLNode, elementName: String? = nil) {
        self.node = node
        self.elementName = elementName
        self.currentTextNodeIndex = 0
    }
    
    mutating func locateNextTextNode() {
        currentTextNodeIndex += 1
    }
}

class XMLDecodingStorage {
    private var stack: [XMLNodeWrapper] = []
    
    func push(_ node: XMLNodeWrapper) {
        stack.append(node)
    }
    
    func push(node: XMLNode) {
        push(XMLNodeWrapper(node: node))
    }
    
    func pop() -> XMLNodeWrapper {
        return stack.removeLast()
    }
    
    var topContainer: XMLNodeWrapper {
        get {
            return stack.last!
        }
    }
    
    func locateNextTextNode() {
        let index = stack.count - 1
        stack[index].locateNextTextNode()
    }
}
