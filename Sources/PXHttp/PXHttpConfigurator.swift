//
//  File.swift
//  
//
//  Created by Pablo Gonzalez on 25/6/21.
//

import Foundation
import Reqres

public class PXHttpConfigurator {
    static var configuration: PXConfiguration?
    
    public static func configure(withConfiguration config: PXConfiguration) {
        configuration = config
    }
    
    static var shouldPrintRequestsWhileDebugging: Bool {
        guard let config = configuration else { return false }
        return config.shouldPrintRequestsWhileDebugging
    }
}

public struct PXConfiguration {
    let shouldPrintRequestsWhileDebugging: Bool
    let authHandler: PXAuthProtocol?
    
    public init(shouldPrintRequestsWhileDebugging: Bool,
                authHandler: PXAuthProtocol? = nil) {
        self.shouldPrintRequestsWhileDebugging = shouldPrintRequestsWhileDebugging
        self.authHandler = authHandler
    }
}

public protocol PXAuthProtocol {
    func addAuthHeader(url: URLRequest) -> URLRequest
    func handleAuthFailure(url: URLRequest,
                           completion: @escaping (Result<URLRequest, Error>) -> Void)
}
