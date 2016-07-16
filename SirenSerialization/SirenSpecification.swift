//
//  SirenSpecification.swift
//  SirenSerialization
//
//  Created by Donald Ness on 7/16/16.
//  Copyright © 2016 Donald Ness. All rights reserved.
//

import Foundation

protocol SirenRoot: SirenEntity {}

protocol SirenEntity {
    var classNames: [String]? { get }
    var properties: [String: AnyObject]? { get }
    var entities: [SirenSubEntityType]? { get }
    var links: [SirenLink]? { get }
    var actions: [SirenAction]? { get }
    var title: String? { get }
}

typealias SirenSubEntityType = SirenSubEntity<SirenLink, SirenEmbeddedEntity>

enum SirenSubEntity<Link, Entity> {
    case embeddedLink(Link)
    case embeddedEntity(Entity)
}

protocol SirenEmbeddedEntity: SirenEntity {
    var rel: [String] { get }
}

protocol SirenLink {
    var rel: [String] { get }
    var classNames: [String]? { get }
    var href: String { get }
    var hrefURL: NSURL { get }
    var title: String? { get }
    var type: String? { get }
}

protocol SirenAction {
    var name: String { get }
    var classNames: [String]? { get }
    var method: String { get }
    var title: String? { get }
    var href: String { get }
    var hrefURL: NSURL { get }
    var type: String? { get }
    var fields: [SirenField]? { get }
}

protocol SirenField {
    var name: String { get }
    var classNames: [String]? { get }
    var type: String { get }
    var value: AnyObject? { get }
    var title: AnyObject? { get }
}
