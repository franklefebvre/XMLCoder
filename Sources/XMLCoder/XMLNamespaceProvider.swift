//
//  XMLNamespaceProvider.swift
//  XMLCoder
//
//  Created by Frank on 13/09/2018.
//

import Foundation

// Must be a class: addressed by reference
final class XMLNamespaceProvider {
    var defaultURI: String?
    var mapping: [String: String] // key: URI, value: name
    var names: Set<String>
    let prefix = "ns"
    
    init() {
        self.mapping = [:]
        self.names = []
    }
    
    func name(for uri: String) -> String? {
        if uri == defaultURI {
            return nil
        }
        if let name = mapping[uri] {
            return name
        }
        let name = newName()
        mapping[uri] = name
        return name
    }
    
    func newName() -> String {
        var n = 1
        while true {
            let name = "\(prefix)\(n)"
            if !names.contains(name) {
                names.insert(name)
                return name
            }
            n += 1
        }
    }
}

extension XMLElement {
    func addNamespaces(from provider: XMLNamespaceProvider) {
        var namespaces: [XMLNode] = []
        if let defaultNamespaceURI = provider.defaultURI {
            let namespaceNode = XMLNode.namespace(withName: "", stringValue: defaultNamespaceURI) as! XMLNode
            namespaces.append(namespaceNode)
        }
        for (namespaceURI, namespaceName) in provider.mapping {
            let namespaceNode = XMLNode.namespace(withName: namespaceName, stringValue: namespaceURI) as! XMLNode
            namespaces.append(namespaceNode)
        }
        self.namespaces = namespaces
    }
}
