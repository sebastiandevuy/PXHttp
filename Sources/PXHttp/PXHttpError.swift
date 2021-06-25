//
//  File.swift
//  
//
//  Created by Pablo Gonzalez on 25/6/21.
//

import Foundation

public enum PXHttpError: Error, Equatable {
    case badResponse
    case badStatusCode(code: Int)
    case dataTaskError(description: String)
    case badURL
    case serialization
    case unAuthenticated
    case noToken
    case unknown
}
