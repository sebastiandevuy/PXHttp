//
//  File.swift
//  
//
//  Created by Pablo Gonzalez on 25/6/21.
//

import Foundation

public struct PXHttpRequest {
    let urlString: String
    let method: PXHttpMethod
    let payload: Encodable?
    let headers: [String: String]?
    let cachePolicy: URLRequest.CachePolicy
    let contentType: ContentType = .json
    
    public init<T>(urlString: String,
            method: PXHttpMethod,
            payload: T,
            headers: [String: String]? = nil,
            cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData) where T: Encodable {
        self.urlString = urlString
        self.method = method
        self.payload = payload
        self.headers = headers
        self.cachePolicy = cachePolicy
    }
    
    public init(urlString: String,
         method: PXHttpMethod,
         headers: [String: String]? = nil,
         cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData) {
        self.urlString = urlString
        self.method = method
        self.payload = nil
        self.headers = headers
        self.cachePolicy = cachePolicy
    }
}

public extension PXHttpRequest {
    enum PXHttpMethod: String {
        case get = "GET"
        case put = "PUT"
        case post = "POST"
        case delete = "DELETE"
    }
    
    enum ContentType: String {
        case json = "application/json"
    }
}
