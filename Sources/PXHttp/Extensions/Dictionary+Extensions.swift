//
//  File.swift
//  
//
//  Created by Pablo Gonzalez on 26/6/21.
//

import Foundation

extension Dictionary where Key == String {
    func urlWithQueryString(url: URL) -> URL? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        var queryItems = [URLQueryItem]()
        
        self.forEach { key, value in
            let dicKey = key
            if let intValue = value as? Int {
                queryItems.append(URLQueryItem(name: dicKey, value: String(intValue)))
            } else if let stringValue = value as? String {
                queryItems.append(URLQueryItem(name: dicKey, value: stringValue))
            } else if let boolValue = value as? Bool {
                queryItems.append(URLQueryItem(name: dicKey, value: boolValue ? "true" : "false"))
            } else if let doubleValue = value as? Double {
                queryItems.append(URLQueryItem(name: dicKey, value: String(doubleValue)))
            }
        }
        
        components?.queryItems = queryItems
        
        return components?.url
    }
}
