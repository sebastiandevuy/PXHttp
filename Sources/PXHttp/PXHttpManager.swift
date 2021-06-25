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
    
    private init() {
        // Refactor eventually
        #if DEBUG
            let config = Reqres.defaultSessionConfiguration()
            config.timeoutIntervalForRequest = 120
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            urlSession = URLSession(configuration: config)
        #else
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 120
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            urlSession = URLSession(configuration: config)
        #endif
    }
    
    public func makeRequest(_ request: PXHttpRequest) -> AnyPublisher<Data, PXHttpError>  {
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

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
    
    var jsonData: Data? {
        guard let dictionary = dictionary else { return nil }
        return try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
    }
}

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
