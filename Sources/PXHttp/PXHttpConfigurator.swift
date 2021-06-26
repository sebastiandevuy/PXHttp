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
    weak var authHandler: PXAuthDelegate?
    
    public init(shouldPrintRequestsWhileDebugging: Bool,
                authHandler: PXAuthDelegate? = nil) {
        self.shouldPrintRequestsWhileDebugging = shouldPrintRequestsWhileDebugging
        self.authHandler = authHandler
    }
}


/// Notifies client application about authentication related events
public protocol PXAuthDelegate: AnyObject {
    
    /// Asks the client to update the request for authorization header
    /// - Parameter url: url to have authorization header added
    func addAuthHeader(url: URLRequest) -> URLRequest
    
    /// Notifies the client that an authorization error happened for the given url, providing opportunity to check if it need to handle auth for the given url, and if so, update credentials and update the request with the new auth header
    /// When this happens the library will queue requests until this methods returns a completion. So you only need to update the authorization once, so check if the auth mechanism you are using is valid between calls in order to just update the headers or start an auth request. Ex: (check if the token expiration time is valid, or has not been updated in a previous call)
    /// - Parameters:
    ///   - url: url to have updated authorization header added
    ///   - completion: completion to notify the library with the updated url with new authorization headers or an error
    func handleAuthFailure(url: URLRequest,
                           completion: @escaping (Result<URLRequest, Error>) -> Void)
}
