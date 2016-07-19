//
//  JSONSirenSerialization.swift
//  SirenSerialization
//
//  Created by Donald Ness on 7/16/16.
//  Copyright © 2016 Donald Ness. All rights reserved.
//

import Foundation

public typealias JSONSiren = JSONSirenEntity
public typealias JSONSirenEntity = JSONSirenSerialization.Entity
public typealias JSONSirenSubEntity = JSONSirenSerialization.SubEntity
public typealias JSONSirenEmbeddedEntity = JSONSirenSerialization.EmbeddedEntity
public typealias JSONSirenLink = JSONSirenSerialization.Link
public typealias JSONSirenAction = JSONSirenSerialization.Action
public typealias JSONSirenField = JSONSirenSerialization.Field

public class JSONSirenSerialization {

    public struct Entity {
        public let classNames: [String]?
        public let properties: [String: AnyObject]?
        public let entities: [SubEntity]?
        public let links: [Link]?
        public let actions: [Action]?
        public let title: String?
    }
    
    public enum SubEntity {
        case embeddedLink(Link)
        case embeddedEntity(EmbeddedEntity)
    }
    
    public struct EmbeddedEntity {
        public let rel: [String]
        public let classNames: [String]?
        public let properties: [String: AnyObject]?
        public let entities: [SubEntity]?
        public let links: [Link]?
        public let actions: [Action]?
        public let title: String?
    }
    
    public struct Link {
        public let rel: [String]
        public let hrefURL: NSURL
        public var href: String { return hrefURL.absoluteString }
        public let classNames: [String]?
        public let title: String?
        public let type: String?
    }
    
    public struct Action {
        public let name: String
        public let hrefURL: NSURL
        public var href: String { return hrefURL.absoluteString }
        public let method: String
        public let classNames: [String]?
        public let title: String?
        public let type: String?
        public let fields: [Field]?
    }
    
    public struct Field {
        public let name: String
        public let type: String
        public let classNames: [String]?
        public let value: AnyObject?
        public let title: String?
    }

    public enum Error: ErrorType {
        case invalidJSONObject
        case missingSubEntityRel
        case missingEmbeddedLinkRel
        case missingEmbeddedLinkHref
        case invalidEmbeddedLinkHref(String)
        case missingActionName
        case missingActionHref
        case invalidActionHref(String)
        case missingFieldName
    }
    
    // MARK: Parse

    public class func JSONSirenValueWithData(data: NSData) throws -> JSONSiren {
        return try parse(try NSJSONSerialization.JSONObjectWithData(data, options: []))
    }
    
    static func parse(JSON: AnyObject) throws -> JSONSiren {
        guard let JSON = JSON as? [String: AnyObject] else {
            throw Error.invalidJSONObject
        }
        return try parseEntity(JSON)
    }
    
    static func parseEntity(JSON: [String: AnyObject]) throws -> Entity {
        let classNames = JSON["class"] as? [String]
        let properties = JSON["properties"] as? [String: AnyObject]
        let entities = try parseSubEntities(JSON["entities"] as? [[String: AnyObject]])
        let links = try parseLinks(JSON["links"] as? [[String: AnyObject]])
        let actions = try parseActions(JSON["actions"] as? [[String: AnyObject]])
        let title = JSON["title"] as? String
        return Entity(classNames: classNames, properties: properties, entities: entities, links: links, actions: actions, title: title)
    }
    
    static func parseSubEntities(JSON: [[String: AnyObject]]?) throws -> [SubEntity]? {
        return try JSON?.flatMap { try parseSubEntity($0) }
    }
    
    static func parseSubEntity(JSON: [String: AnyObject]?) throws -> SubEntity? {
        guard let JSON = JSON else {
            return nil
        }
        if JSON.keys.contains("href") {
            return SubEntity.embeddedLink(try parseLink(required: JSON))
        }
        else {
            return SubEntity.embeddedEntity(try parseEmbeddedEntity(JSON))
        }
    }
    
    static func parseEmbeddedEntity(JSON: [String: AnyObject]) throws -> EmbeddedEntity {
        guard let rel = JSON["rel"] as? [String] else {
            throw Error.missingSubEntityRel
        }
        let classNames = JSON["class"] as? [String]
        let properties = JSON["properties"] as? [String: AnyObject]
        let entities = try parseSubEntities(JSON["entities"] as? [[String: AnyObject]])
        let links = try parseLinks(JSON["links"] as? [[String: AnyObject]])
        let actions = try parseActions(JSON["actions"] as? [[String: AnyObject]])
        let title = JSON["title"] as? String
        return EmbeddedEntity(rel: rel, classNames: classNames, properties: properties, entities: entities, links: links, actions: actions, title: title)
    }
    
    static func parseLinks(JSON: [[String: AnyObject]]?) throws -> [Link]? {
        return try JSON?.flatMap { try parseLink(optional: $0) }
    }
    
    static func parseLink(optional JSON: [String: AnyObject]?) throws -> Link? {
        guard let JSON = JSON else {
            return nil
        }
        return try parseLink(required: JSON)
    }
    
    static func parseLink(required JSON: [String: AnyObject]) throws -> Link {
        guard let rel = JSON["rel"] as? [String] else {
            throw Error.missingEmbeddedLinkRel
        }
        guard let href = JSON["href"] as? String else {
            throw Error.missingEmbeddedLinkHref
        }
        guard let hrefURL = NSURL(string: href) else {
            throw Error.invalidEmbeddedLinkHref(href)
        }
        let classNames = JSON["class"] as? [String]
        let title = JSON["title"] as? String
        let type = JSON["type"] as? String
        return Link(rel: rel, hrefURL: hrefURL, classNames: classNames, title: title, type: type)
    }
    
    static func parseActions(JSON: [[String: AnyObject]]?) throws -> [Action]? {
        return try JSON?.flatMap { try parseAction(optional: $0) }
    }
    
    static func parseAction(optional JSON: [String: AnyObject]?) throws -> Action? {
        guard let JSON = JSON else {
            return nil
        }
        return try parseAction(required: JSON)
    }
    
    static func parseAction(required JSON: [String: AnyObject]) throws -> Action {
        guard let name = JSON["name"] as? String else {
            throw Error.missingActionName
        }
        guard let href = JSON["href"] as? String else {
            throw Error.missingActionHref
        }
        guard let hrefURL = NSURL(string: href) else {
            throw Error.invalidActionHref(href)
        }
        let method = JSON["method"] as? String ?? "GET"
        let classNames = JSON["class"] as? [String]
        let title = JSON["title"] as? String
        let type = JSON["type"] as? String
        let fields = try parseFields(JSON["fields"] as? [[String: AnyObject]])
        return Action(name: name, hrefURL: hrefURL, method: method, classNames: classNames, title: title, type: type, fields: fields)
    }
    
    static func parseFields(JSON: [[String: AnyObject]]?) throws -> [Field]? {
        return try JSON?.flatMap { try parseField(optional: $0) }
    }
    
    static func parseField(optional JSON: [String: AnyObject]?) throws -> Field? {
        guard let JSON = JSON else {
            return nil
        }
        return try parseField(required: JSON)
    }
    
    static func parseField(required JSON: [String: AnyObject]) throws -> Field {
        guard let name = JSON["name"] as? String else {
            throw Error.missingFieldName
        }
        let type = JSON["type"] as? String ?? "text"
        let classNames = JSON["class"] as? [String]
        let value = JSON["value"]
        let title = JSON["title"] as? String
        return Field(name: name, type: type, classNames: classNames, value: value, title: title)
    }
    
    // MARK: Serialize
    
    public class func dataWithJSONSirenValue(value: JSONSiren, options opt: NSJSONWritingOptions) throws -> NSData {
        return NSData()
    }

}
