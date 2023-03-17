//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/3/16.
//

import Foundation

/// Protocol representing a network request handler.
/// Implement this protocol to perform actual network request.
///
/// The default one is ``AlamofireAdaptor``.
public protocol NetworkAdaptor {
    /// Send network request and get the decodable result.
    /// - parameter request: request containing the parameters for a request, like request body and http method.
    /// - parameter configuration: common configuration for a request, like common headers.
    func request<T>(request: any AIRequest, configuration: SessionConfiguration) async throws -> T where T: Decodable
    
    /// Send network request and get the ``AsyncThrowingStream`` result.
    /// - parameter request: request containing the parameters for a request, like request body and http method.
    /// - parameter configuration: common configuration for a request, like common headers.
    /// - parameter transformer: how the data is transformed before being yield to ``AsyncThrowingStream``.
    func stream<T, R>(request: any AIRequest,
                      configuration: SessionConfiguration,
                      transformer: @escaping (T) -> R) -> AsyncThrowingStream<R, Error> where T: Codable
}

/// Configuration containing common parameters like default headers.
public struct SessionConfiguration {
    public fileprivate(set) var defaultHeaders: [String: String] = [:]
    
    public init(defaultHeaders: [String : String]) {
        self.defaultHeaders = defaultHeaders
    }
}
