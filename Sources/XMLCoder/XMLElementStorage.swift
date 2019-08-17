//
//  XMLElementStorage.swift
//  XMLCoder
//
//  Created by Frank on 24/08/2018.
//  Copyright © 2018 Frank Lefebvre. All rights reserved.
//

import Foundation

enum XMLNodeType {
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

protocol XMLQualifiedKey {
    var namespace: String? { get }
}

protocol XMLTypedKey {
    var nodeType: XMLNodeType { get }
}

protocol XMLArrayKey {
    static var elementName: String { get }
}

// MARK: Decoding

class XMLDecodingStorage {
    private var stack: [XMLNode] = []
    
    func push(node: XMLNode) {
        stack.append(node)
    }
    
    func pop() -> XMLNode {
        return stack.removeLast()
    }
    
    var topContainer: XMLNode {
        get {
            return stack.last!
        }
    }
}
