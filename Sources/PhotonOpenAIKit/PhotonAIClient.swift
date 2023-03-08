//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/3/8.
//

import Foundation
import Alamofire
import AlamofireEventSource

/// Entry point to communicate with OpenAI Platform.
/// - Construct your own ``PhotonAIClient`` with an api key and keep reference to it.
/// - Use one of the property to start request, like ``chatCompletion``.
///
/// ```
/// let client = PhotonAIClient(apiKey: "you_api_key")
/// let chatCompletion = chat.chatCompletion
///
/// // Use chatCompletion to send request. See more in ``ChatCompletion``.
/// ```
public class PhotonAIClient {
    /// Error that would be thrown during request.
    /// You use ``message`` to check the message info.
    ///
    /// If the response contains status code that is not between 200-300,
    /// then ``code`` is set.
    ///
    /// To get the general information:
    /// ```
    /// let errorMessage = String(describing: error)
    /// ```
    public struct RequestError: Error, CustomStringConvertible {
        public let message: String
        public let code: Int
        
        init(_ message: String = "", code: Int = -1) {
            self.message = message
            self.code = code
        }
        
        /// Description about ``message`` and ``code``.
        public var description: String {
            return "Error: \(message) code: \(code)"
        }
    }
        
    /// Retrieve the ``ChatCompletion`` to start request.
    public let chatCompletion: ChatCompletion

    /// Handle HTTP request.
    private let handler: RequestHandler

    /// Init this client with ``apiKey``, which can be obtained from OpenAI Platform:
    /// https://platform.openai.com/account/api-keys
    ///
    /// If the ``apiKey`` is changed, you simply reconstruct the ``PhotonAIClient`` and deinit the old one.
    public init(apiKey: String) {
        var defaultHeaders = Dictionary<String, String>()
        defaultHeaders["Authorization"] = "Bearer \(apiKey)"
        defaultHeaders["Content-Type"] = "application/json"
        
        handler = RequestHandler(defaultHeaders: defaultHeaders)
        chatCompletion = ChatCompletion(handler: handler)
    }
}

class RequestHandler {
    private let jsonEncoder = JSONEncoder()
    fileprivate var defaultHeaders = Dictionary<String, String>()
    
    init(defaultHeaders: Dictionary<String, String> = Dictionary<String, String>()) {
        self.defaultHeaders = defaultHeaders
    }
    
    func stream<T, R>(request: any AIRequest,
                      transformer: @escaping (T) -> R) -> AsyncThrowingStream<R, Error> where T: Codable {
        return AsyncThrowingStream { continuation in
            runOnDefaultLog { logger in
                logger.log("start request \(request.url)")
            }
            
            if !request.streamMode {
                continuation.finish(throwing: PhotonAIClient.RequestError("Request is not set to stream mode."))
                return
            }
            
            let streamReqeust = createAFStreamRequest(request: request).responseDecodableEventSource { (source: DataStreamRequest.DecodableEventSource<T>) in
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
                streamReqeust.cancel()
            }
        }
    }
    
    private func createAFStreamRequest(request: any AIRequest) -> Alamofire.DataStreamRequest {
        return AF.streamRequest(request.url,
                                method: request.getAlamofireMethod()) { r in
            for (name, value) in self.defaultHeaders {
                r.headers.add(name: name, value: value)
            }
            
            if let bodyData = try? self.jsonEncoder.encode(request.body) {
                r.httpBody = bodyData
            }
        }
    }
}

extension DataStreamRequest.Completion {
    func tryGetError() -> Error? {
        let error: Error?
        
        if self.error != nil {
            error = PhotonAIClient.RequestError(self.error?.errorDescription ?? "Unknown error description")
        } else if let response = self.response,
                  !(200..<300).contains(response.statusCode) {
            error = PhotonAIClient.RequestError("Response with non-success status code", code: response.statusCode)
        } else {
            error = nil
        }
        
        return error
    }
}
