//
//  XMLNamespaceProvider.swift
//  XMLCoder
//
//  Created by Frank on 13/09/2018.
//

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

// Must be a class: addressed by reference
final class XMLNamespaceProvider {
    var defaultURI: String?
    var mapping: [String: String] // key: URI, value: name
    var names: Set<String>
    let prefix: String
    
    init(defaultURI: String? = nil, initialMapping: [String: String] = [:], namePrefix: String = "ns") {
        self.defaultURI = defaultURI
        self.mapping = initialMapping
        self.names = Set(initialMapping.values)
        self.prefix = namePrefix
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
        if let defaultNamespaceURI = provider.defaultURI {
            self.addNamespace(withName: "", stringValue: defaultNamespaceURI)
        }
        for (namespaceURI, namespaceName) in provider.mapping {
            self.addNamespace(withName: namespaceName, stringValue: namespaceURI)
        }
    }
    
    func addNamespace(withName namespaceName: String, stringValue: String) {
        let namespaceNode = XMLNode.namespace(withName: namespaceName, stringValue: stringValue) as! XMLNode
        self.addNamespace(namespaceNode)
    }
    
    var qualifiedName: String? {
        guard let localName = self.localName else {
            return nil
        }
        guard let namespaceURI = self.uri else {
            return localName
        }
        return "\(namespaceURI):\(localName)"
    }
}
