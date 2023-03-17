//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/3/16.
//

import Foundation
import Alamofire
import AlamofireEventSource
import PhotonOpenAIBase

/// A ``NetworkAdaptor`` implemented by ``Alamofire`` framework.
public class AlamofireAdaptor: NetworkAdaptor {
    private let jsonEncoder = JSONEncoder()
    
    public init() {
        // empty
    }
    
    public func request<T>(request: any AIRequest,
                    configuration: SessionConfiguration) async throws -> T where T: Decodable {
        let afRequest = createAFRequest(request: request, configuration: configuration)
        
        return try await withTaskCancellationHandler(operation: {
            return try await self.request(request: afRequest)
        }, onCancel: {
            runOnDefaultLog { logger in
                logger.log("cancel on request \(request.url)")
            }
            afRequest.cancel()
        })
    }
    
    private func request<T>(request: DataRequest) async throws -> T where T: Decodable {
        return try await withCheckedThrowingContinuation { continuation in
            request.responseDecodable(of: T.self) { response in
                if let data = response.value {
                    continuation.resume(returning: data)
                } else {
                    let error = response.tryGetError()
                    
                    if error != nil {
                        continuation.resume(throwing: error!)
                    } else {
                        continuation.resume(throwing: RequestError("Unknown error"))
                    }
                }
            }
        }
    }
    
    public func stream<T, R>(request: any AIRequest,
                      configuration: SessionConfiguration,
                      transformer: @escaping (T) -> R) -> AsyncThrowingStream<R, Error> where T: Codable {
        return AsyncThrowingStream { continuation in
            runOnDefaultLog { logger in
                logger.log("start request \(request.url)")
            }
            
            if !request.streamMode {
                continuation.finish(throwing: RequestError("Request is not set to stream mode."))
                return
            }
            
            let streamRequest = createAFStreamRequest(request: request, configuration: configuration).responseDecodableEventSource { (source: DataStreamRequest.DecodableEventSource<T>) in
                switch source.event {
                case .message(let message):
                    if let data = message.data {
                        let transformed = transformer(data)
                        continuation.yield(transformed)
                    }
                case .complete(let completion):
                    runOnDefaultLog { logger in
                        logger.log("complete, status code: \(String(describing: completion.response?.statusCode))")
                    }
                    
                    let error = completion.tryGetError()
                    
                    if error != nil {
                        continuation.finish(throwing: error)
                    } else {
                        continuation.finish()
                    }
                }
            }
            
            continuation.onTermination = { _ in
                runOnDefaultLog { logger in
                    logger.log("cancel on request \(request.url)")
                }
                streamRequest.cancel()
            }
        }
    }
    
    private func createAFStreamRequest(request: any AIRequest,
                                       configuration: SessionConfiguration) -> Alamofire.DataStreamRequest {
        return AF.streamRequest(request.url,
                                method: request.getAlamofireMethod()) { r in
            self.addHeaders(request: &r, aiReqeust: request, body: request.body, configuration: configuration)
        }
    }
    
    private func createAFRequest(request: any AIRequest,
                                 configuration: SessionConfiguration) -> DataRequest {
        return AF.request(request.url, method: request.getAlamofireMethod()) { r in
            self.addHeaders(request: &r, aiReqeust: request, body: request.body, configuration: configuration)
        }
    }
    
    private func addHeaders(request: inout URLRequest,
                            aiReqeust: any AIRequest,
                            body: Codable,
                            configuration: SessionConfiguration) {
        for (name, value) in configuration.defaultHeaders {
            request.headers.add(name: name, value: value)
        }
        
        if let bodyData = try? self.jsonEncoder.encode(body) {
            request.httpBody = bodyData
        }
    }
}

extension DataResponse {
    func tryGetError() -> Error? {
        let error: Error?
        
        if self.error != nil {
            error = RequestError(self.error?.localizedDescription ?? "Unknown error description")
        } else if let response = self.response,
                  !(200..<300).contains(response.statusCode) {
            error = RequestError("Response with non-success status code", code: response.statusCode)
        } else {
            error = nil
        }
        
        return error
    }
}

extension DataStreamRequest.Completion {
    func tryGetError() -> Error? {
        let error: Error?
        
        if self.error != nil {
            error = RequestError(self.error?.errorDescription ?? "Unknown error description")
        } else if let response = self.response,
                  !(200..<300).contains(response.statusCode) {
            error = RequestError("Response with non-success status code", code: response.statusCode)
        } else {
            error = nil
        }
        
        return error
    }
}

public extension AIRequest {
    func getAlamofireMethod() -> Alamofire.HTTPMethod {
        switch self.method {
        case .post:
            return .post
        default:
            return .get
        }
    }
}
