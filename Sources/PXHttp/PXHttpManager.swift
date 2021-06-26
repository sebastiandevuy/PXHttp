//
//  File.swift
//  
//
//  Created by Pablo Gonzalez on 25/6/21.
//

import Foundation
import Combine
import Reqres

@available(macOS 10.15, *)
public protocol PXHttpManagerProtocol {
    func makeRequest(_ request: PXHttpRequest) -> AnyPublisher<Data, PXHttpError>
}

@available(macOS 10.15, *)
public class PXHTTPManager: PXHttpManagerProtocol {
    public static var shared = PXHTTPManager()
    
    private let urlSession: URLSession
    private var refreshTokenSubscriber: AnyCancellable?
    private let refreshLock = NSLock()
    
    private init() {
        #if DEBUG
        if PXHttpConfigurator.shouldPrintRequestsWhileDebugging {
            let config = Reqres.defaultSessionConfiguration()
            config.timeoutIntervalForRequest = 120
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            urlSession = URLSession(configuration: config)
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 120
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            urlSession = URLSession(configuration: config)
        }
        #else
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        urlSession = URLSession(configuration: config)
        #endif
    }
    
    public func makeRequest(_ request: PXHttpRequest) -> AnyPublisher<Data, PXHttpError>  {
        guard let configuration = PXHttpConfigurator.configuration else {
            return Fail(error: PXHttpError.noConfiguration).eraseToAnyPublisher()
        }
        guard let requestUrl = URL(string: request.urlString) else {
            return Fail(error: PXHttpError.badURL).eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: requestUrl)
        
        if let payload = request.payload {
            switch request.method {
            case .post, .put:
                if request.contentType == .json {
                    guard let jsonPayload = payload.jsonData else {
                        return Fail(error: PXHttpError.serialization).eraseToAnyPublisher()
                    }
                    urlRequest.httpBody = jsonPayload
                }
                urlRequest.addValue(request.contentType.rawValue, forHTTPHeaderField: DefaultHeaders.contentType.rawValue)
            case .get, .delete:
                guard let dictionary = payload.dictionary, let url = dictionary.urlWithQueryString(url: requestUrl) else {
                    return Fail(error: PXHttpError.serialization).eraseToAnyPublisher()
                }
                urlRequest.url = url
            }
        }
        
        urlRequest.httpMethod = request.method.rawValue
        
        // Evaluate additional headers
        if let additionalHeader = request.headers {
            additionalHeader.forEach({
                urlRequest.addValue($0.value, forHTTPHeaderField: $0.key)
            })
        }
        
        // Evaluate authentication prior to making the request
        if let authHandler = configuration.authHandler {
            urlRequest = authHandler.addAuthHeader(url: urlRequest)
        }
        
        return makeRequest(urlRequest)
            .tryCatch({ [weak self] error -> AnyPublisher<Data, PXHttpError> in
                guard let self = self else { throw PXHttpError.unknown }
                if error == .unAuthenticated,
                   let authHandler = configuration.authHandler {
                    self.refreshLock.lock()
                    let result = self.handleAuthFailure(urlRequest: urlRequest, auth: authHandler)
                    self.refreshLock.unlock()
                    switch result {
                    case .success(let request):
                        return self.makeRequest(request)
                    case .failure(let error):
                        throw error
                    }
                } else {
                    throw error
                }
            })
            .mapError { error -> PXHttpError in
                if let raisedError = error as? PXHttpError {
                    return raisedError
                } else {
                    return .dataTaskError(description: error.localizedDescription)
                }
            }.eraseToAnyPublisher()
    }
    
    func handleAuthFailure(urlRequest: URLRequest,
                           auth: PXAuthDelegate) -> Result<URLRequest, Error> {
        var obtainedResult: Result<URLRequest, Error> = .failure(NSError())
        
        let d = DispatchGroup()
        d.enter()
        auth.handleAuthFailure(url: urlRequest) { result in
            obtainedResult = result
            d.leave()
        }
        d.wait()
        return obtainedResult
    }
    
    private func makeRequest(_ urlRequest: URLRequest) -> AnyPublisher<Data, PXHttpError> {
        return urlSession
            .dataTaskPublisher(for: urlRequest)
            .tryMap { (data, response) -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw PXHttpError.badResponse
                }
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    return data
                } else if httpResponse.statusCode == 403 || httpResponse.statusCode == 401 {
                    throw PXHttpError.unAuthenticated
                } else {
                    throw PXHttpError.badStatusCode(code: httpResponse.statusCode)
                }
            }.mapError { error -> PXHttpError in
                if let raisedError = error as? PXHttpError {
                    return raisedError
                } else {
                    return .dataTaskError(description: error.localizedDescription)
                }
            }.eraseToAnyPublisher()
    }
}

@available(macOS 10.15, *)
extension PXHTTPManager {
    private enum DefaultHeaders: String {
        case contentType = "Content-Type"
        case authorization = "Authorization"
    }
}
