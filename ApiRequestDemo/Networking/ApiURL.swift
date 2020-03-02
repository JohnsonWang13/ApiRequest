//
//  ApiURL.swift
//  GoodJob
//
//  Created by Johnson on 2017/7/28.
//  Copyright © 2017年 Johnson. All rights reserved.
//

import Foundation

// MARK: Api Protocol
protocol ApiKey {
    var keys: [String] { get }
    var idForKeys: [Any?] { get }
    // Domain/key1/idForKeys1/key2/idForKeys2
    var httpMethod: HTTPMethod { get }
    var contentType: ContentType { get }
    var apiVersion: String { get }
}

// MARK: - Search
enum ApiKeySearch: ApiKey {
    case searchUser
    
    init(_ apiKey: ApiKeySearch) {
        self = apiKey
    }
    
    var keys: [String] {
        switch self {
        case .searchUser: return ["search","users"]
            
        }
    }
    
    var idForKeys: [Any?] {
        switch self {
        case .searchUser: return []
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .searchUser: return .get
        }
    }
    
    var contentType: ContentType {
        switch self {
        case .searchUser: return .query
        }
    }
    
    var apiVersion: String { return "v1" }
}
