//
//  MessageResult.swift
//  Adpost
//
//  Created by 王富生 on 2018/8/10.
//  Copyright © 2018年 Kurt. All rights reserved.
//

import Foundation

struct MessageResult: Decodable {
    var code: Int?
    var message: String?
    var data: JSONValue?
}


public enum JSONValue: Decodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Not a JSON"))
        }
    }
    
    var stringValue: String? {
        switch self {
        case .string(let string): return string
        default: return nil
        }
    }
    
    var intValue: Int? {
        switch self {
        case .int(let int): return int
        default: return nil
        }
    }
    
    var dictionValue: Dictionary<String, JSONValue>? {
        switch self {
        case .object(let object): return object
        default: return nil
        }
    }
    
    var values: AnyObject {
        switch self {
        case let .array(xs):
            return xs.map { $0.values } as AnyObject
        case let .object(xs):
            return xs.mapValues { $0.values } as AnyObject
        case let .double(n):
            return n as AnyObject
        case let .string(s):
            return s as AnyObject
        case let .bool(b):
            return b as AnyObject
        case let .int(i):
            return i as AnyObject
        }
    }
}
