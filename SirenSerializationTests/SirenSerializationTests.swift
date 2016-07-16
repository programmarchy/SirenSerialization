//
//  SirenSerializationTests.swift
//  SirenSerializationTests
//
//  Created by Donald Ness on 7/16/16.
//  Copyright © 2016 Donald Ness. All rights reserved.
//

import XCTest
@testable import SirenSerialization

class SirenSerializationTests: XCTestCase {

    struct Examples {
        static var orderData: NSData {
            return readFile("order", ofType: "json")
        }
        
        static var zettaRootData: NSData {
            return readFile("zetta_root", ofType: "json")
        }
        
        static var zettaServerData: NSData {
            return readFile("zetta_server", ofType: "json")
        }
        
        static func readFile(name: String, ofType type: String?) -> NSData {
            let bundle = NSBundle(forClass: SirenSerializationTests.self)
            let path = bundle.pathForResource(name, ofType: type)!
            return NSData(contentsOfFile: path)!
        }
    }
    
    func testParseOrder() {
        do {
            let data = Examples.orderData
            let root = try JSONSirenSerialization.JSONSirenValueWithData(data)
            
            guard let classNames = root.classNames else {
                XCTFail("has a class")
                return
            }
            XCTAssertEqual(classNames.count, 1)
            XCTAssert(classNames.contains("order"), "has the class")
            
            guard let properties = root.properties else {
                XCTFail("has properties")
                return
            }
            XCTAssertEqual(properties.count, 3)
            XCTAssertEqual(properties["orderNumber"] as? Int, 42)
            XCTAssertEqual(properties["itemCount"] as? NSNumber, 3)
            XCTAssertEqual(properties["status"] as? String, "pending")
            
            guard let entities = root.entities else {
                XCTFail("has entities")
                return
            }
            XCTAssertEqual(entities.count, 2)
            
            switch entities[0] {
            case .embeddedLink(let link):
                guard let classNames = link.classNames else {
                    XCTFail("has a class")
                    return
                }
                XCTAssertEqual(classNames.count, 2)
                XCTAssert(classNames.contains("items"), "has the class")
                XCTAssert(classNames.contains("collection"), "has the class")
                
                XCTAssertEqual(link.rel.count, 1)
                XCTAssertEqual(link.rel[0], "http://x.io/rels/order-items")
                
                XCTAssertEqual(link.href, "http://api.x.io/orders/42/items")
            default:
                XCTFail("subentity is embedded link")
            }
            
            switch entities[1] {
            case .embeddedEntity(let entity):
                guard let classNames = entity.classNames else {
                    XCTFail("has a class")
                    return
                }
                XCTAssertEqual(classNames.count, 2)
                XCTAssert(classNames.contains("info"), "has the class")
                XCTAssert(classNames.contains("customer"), "has the class")
                
                XCTAssertEqual(entity.rel.count, 1)
                XCTAssertEqual(entity.rel[0], "http://x.io/rels/customer")
                
                guard let properties = entity.properties else {
                    XCTFail("has properties")
                    return
                }
                XCTAssertEqual(properties.count, 2)
                XCTAssertEqual(properties["customerId"] as? String, "pj123")
                XCTAssertEqual(properties["name"] as? String, "Peter Joseph")
                
                guard let links = entity.links else {
                    XCTFail("has links")
                    return
                }
                XCTAssertEqual(links.count, 1)
                XCTAssertEqual(links[0].rel.count, 1)
                XCTAssertEqual(links[0].rel[0], "self")
                XCTAssertEqual(links[0].href, "http://api.x.io/customers/pj123")
            default:
                XCTFail("subentity is embedded entity")
            }

            guard let actions = root.actions else {
                XCTFail("has actions")
                return
            }
            XCTAssertEqual(actions.count, 1)
            XCTAssertEqual(actions[0].name, "add-item")
            XCTAssertEqual(actions[0].title, "Add Item")
            XCTAssertEqual(actions[0].method, "POST")
            XCTAssertEqual(actions[0].href, "http://api.x.io/orders/42/items")
            XCTAssertEqual(actions[0].type, "application/x-www-form-urlencoded")
            
            guard let fields = actions[0].fields else {
                XCTFail("has fields")
                return
            }
            XCTAssertEqual(fields.count, 3)
            XCTAssertEqual(fields[0].name, "orderNumber")
            XCTAssertEqual(fields[0].type, "hidden")
            XCTAssertEqual(fields[0].value as? String, "42")
            XCTAssertEqual(fields[1].name, "productCode")
            XCTAssertEqual(fields[1].type, "text")
            XCTAssertEqual(fields[2].name, "quantity")
            XCTAssertEqual(fields[2].type, "number")
            
            guard let links = root.links else {
                XCTFail("has links")
                return
            }
            XCTAssertEqual(links.count, 3)
            XCTAssertEqual(links[0].rel.count, 1)
            XCTAssertEqual(links[0].rel[0], "self")
            XCTAssertEqual(links[0].href, "http://api.x.io/orders/42")
            XCTAssertEqual(links[1].rel.count, 1)
            XCTAssertEqual(links[1].rel[0], "previous")
            XCTAssertEqual(links[1].href, "http://api.x.io/orders/41")
            XCTAssertEqual(links[2].rel.count, 1)
            XCTAssertEqual(links[2].rel[0], "next")
            XCTAssertEqual(links[2].href, "http://api.x.io/orders/43")
        }
        catch let error as NSError {
            XCTFail(error.description)
        }
    }
    
    func testParseZettaRoot() {
        do {
            let data = Examples.zettaRootData
            let root = try JSONSirenSerialization.JSONSirenValueWithData(data)
            
            guard let classNames = root.classNames else {
                XCTFail("has a class")
                return
            }
            XCTAssertEqual(classNames.count, 1)
            XCTAssert(classNames.contains("root"), "has the class")
            
            XCTAssertNil(root.properties, "has no properties")
            XCTAssertNil(root.entities, "has no entities")

            guard let links = root.links else {
                XCTFail("has links")
                return
            }
            XCTAssertEqual(links.count, 5)
            XCTAssertEqual(links[0].rel.count, 1)
            XCTAssertEqual(links[0].rel[0], "self")
            XCTAssertEqual(links[0].href, "https://api.zettajs.io/v1/")
            XCTAssertEqual(links[1].rel.count, 1)
            XCTAssertEqual(links[1].rel[0], "http://rels.zettajs.io/peer-management")
            XCTAssertEqual(links[1].href, "https://api.zettajs.io/v1/peer-management")
            XCTAssertEqual(links[2].rel.count, 1)
            XCTAssertEqual(links[2].rel[0], "http://rels.zettajs.io/events")
            XCTAssertEqual(links[2].href, "wss://api.zettajs.io/v1/events")
            XCTAssertEqual(links[3].title, "8efe0791-be55-4097-842a-0383d9816f90")
            XCTAssertEqual(links[3].rel.count, 2)
            XCTAssertEqual(links[3].rel[0], "http://rels.zettajs.io/peer")
            XCTAssertEqual(links[3].rel[1], "http://rels.zettajs.io/server")
            XCTAssertEqual(links[3].href, "https://api.zettajs.io/v1/servers/8efe0791-be55-4097-842a-0383d9816f90")
            XCTAssertEqual(links[4].title, "b51eea98-3de4-4dfa-97fe-4f0d6ec2dd39")
            XCTAssertEqual(links[4].rel.count, 2)
            XCTAssertEqual(links[4].rel[0], "http://rels.zettajs.io/peer")
            XCTAssertEqual(links[4].rel[1], "http://rels.zettajs.io/server")
            XCTAssertEqual(links[4].href, "https://api.zettajs.io/v1/servers/b51eea98-3de4-4dfa-97fe-4f0d6ec2dd39")

            guard let actions = root.actions else {
                XCTFail("has actions")
                return
            }
            XCTAssertEqual(actions.count, 1)
            XCTAssertEqual(actions[0].name, "query-devices")
            XCTAssertNil(actions[0].title)
            XCTAssertEqual(actions[0].method, "GET")
            XCTAssertEqual(actions[0].href, "https://api.zettajs.io/v1/")
            XCTAssertEqual(actions[0].type, "application/x-www-form-urlencoded")
            
            guard let fields = actions[0].fields else {
                XCTFail("has fields")
                return
            }
            XCTAssertEqual(fields.count, 2)
            XCTAssertEqual(fields[0].name, "server")
            XCTAssertEqual(fields[0].type, "text")
            XCTAssertNil(fields[0].value)
            XCTAssertEqual(fields[1].name, "ql")
            XCTAssertEqual(fields[1].type, "text")
            XCTAssertNil(fields[1].value)
        }
        catch let error as NSError {
            XCTFail(error.description)
        }
    }
    
    func testParseZettaServer() {
        do {
            let data = Examples.zettaServerData
            let root = try JSONSirenSerialization.JSONSirenValueWithData(data)
            
            guard let classNames = root.classNames else {
                XCTFail("has a class")
                return
            }
            XCTAssertEqual(classNames.count, 1)
            XCTAssert(classNames.contains("server"), "has the class")
            
            guard let properties = root.properties else {
                XCTFail("has properties")
                return
            }
            XCTAssertEqual(properties.count, 1)
            XCTAssertEqual(properties["name"] as? String, "b51eea98-3de4-4dfa-97fe-4f0d6ec2dd39")
            
            guard let entities = root.entities else {
                XCTFail("has entities")
                return
            }
            XCTAssertEqual(entities.count, 10)
            
            switch entities[0] {
            case .embeddedEntity(let entity):
                guard let classNames = entity.classNames else {
                    XCTFail("has a class")
                    return
                }
                XCTAssertEqual(classNames.count, 2)
                XCTAssert(classNames.contains("device"), "has the class")
                XCTAssert(classNames.contains("service"), "has the class")
                
                XCTAssertEqual(entity.rel.count, 1)
                XCTAssertEqual(entity.rel[0], "http://rels.zettajs.io/device")
                
                guard let properties = entity.properties else {
                    XCTFail("has properties")
                    return
                }
                XCTAssertEqual(properties.count, 10)
                
                guard let links = entity.links else {
                    XCTFail("has links")
                    return
                }
                XCTAssertEqual(links.count, 3)
            default:
                XCTFail("subentity is embedded entity")
            }

            guard let links = root.links else {
                XCTFail("has links")
                return
            }
            XCTAssertEqual(links.count, 3)
            XCTAssertEqual(links[0].rel.count, 1)
            XCTAssertEqual(links[0].rel[0], "self")
            XCTAssertEqual(links[0].href, "https://api.zettajs.io/v1/servers/b51eea98-3de4-4dfa-97fe-4f0d6ec2dd39")
            XCTAssertEqual(links[1].rel.count, 1)
            XCTAssertEqual(links[1].rel[0], "http://rels.zettajs.io/metadata")
            XCTAssertEqual(links[1].href, "https://api.zettajs.io/v1/servers/b51eea98-3de4-4dfa-97fe-4f0d6ec2dd39/meta")
            XCTAssertEqual(links[2].rel.count, 1)
            XCTAssertEqual(links[2].rel[0], "monitor")
            XCTAssertEqual(links[2].href, "wss://api.zettajs.io/v1/servers/b51eea98-3de4-4dfa-97fe-4f0d6ec2dd39/events?topic=logs")

            guard let actions = root.actions else {
                XCTFail("has actions")
                return
            }
            XCTAssertEqual(actions.count, 1)
            XCTAssertEqual(actions[0].name, "query-devices")
            XCTAssertNil(actions[0].title)
            XCTAssertEqual(actions[0].method, "GET")
            XCTAssertEqual(actions[0].href, "https://api.zettajs.io/v1/servers/b51eea98-3de4-4dfa-97fe-4f0d6ec2dd39")
            XCTAssertEqual(actions[0].type, "application/x-www-form-urlencoded")
            
            guard let fields = actions[0].fields else {
                XCTFail("has fields")
                return
            }
            XCTAssertEqual(fields.count, 1)
            XCTAssertEqual(fields[0].name, "ql")
            XCTAssertEqual(fields[0].type, "text")
            XCTAssertNil(fields[0].value)
        }
        catch let error as NSError {
            XCTFail(error.description)
        }
    }
    
}
