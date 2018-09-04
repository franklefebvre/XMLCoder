//
//  XMLElementContainers.swift
//  XMLCoder
//
//  Created by Frank on 24/08/2018.
//  Copyright © 2018 Frank Lefebvre. All rights reserved.
//

import Foundation

protocol XMLEncodingContainer {
    var nodes: [XMLNode] { get }
}

class UnkeyedXMLElementContainer: XMLEncodingContainer {
    var nodes: [XMLNode] = []
}

class KeyedXMLElementContainer: XMLEncodingContainer {
    var nodes: [XMLNode] = []
}

class SingleXMLElementContainer: XMLEncodingContainer {
    var nodes: [XMLNode] = []
}
