//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/3/8.
//

import Foundation
import PhotonOpenAIBase

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
    /// Retrieve the ``ChatCompletion`` to start request.
    public let chatCompletion: ChatCompletion

    /// Handle HTTP request.
    private let handler: RequestHandler

    /// Azure mode
    public let azure: Bool
    
    /// Init this client with ``apiKey``, ``NetworkAdapter``, ``scheme`` and ``host``.
    ///
    /// If the ``apiKey`` is changed, you simply reconstruct the ``PhotonAIClient`` and deinit the old one.
    ///
    /// - parameter apiKey: The api key associated with your account
    /// - parameter withAdaptor: The instance of NetworkAdaptor protocol to send network request
    /// - parameter scheme: The url scheme, default to "https"
    /// - parameter host: The url host, default to "api.openai.com"
    public init(apiKey: String,
                withAdaptor: any NetworkAdaptor,
                scheme: String = "https",
                host: String = openAIHost,
                path: String? = nil,
                azure: Bool = false) {
        var defaultHeaders = Dictionary<String, String>()

        if azure {
            defaultHeaders["api-key"] = "\(apiKey)"
        } else {
            defaultHeaders["Authorization"] = "Bearer \(apiKey)"
        }

        defaultHeaders["Content-Type"] = "application/json"
        
        let configuration = SessionConfiguration(defaultHeaders: defaultHeaders, scheme: scheme, host: host)
        
        self.azure = azure
        handler = RequestHandler(adaptor: withAdaptor, configuration: configuration)
        chatCompletion = ChatCompletion(handler: handler)
    }
}

class RequestHandler: NetworkAdaptor {
    private let adaptor: any NetworkAdaptor
    let configuration: SessionConfiguration
    
    init(adaptor: any NetworkAdaptor, configuration: SessionConfiguration) {
        self.adaptor = adaptor
        self.configuration = configuration
    }
    
    func request<T>(request: any AIRequest,
                    configuration: SessionConfiguration) async throws -> T where T : Decodable {
        return try await adaptor.request(request: request, configuration: configuration)
    }
    
    func stream<T, R>(request: any AIRequest,
                      configuration: SessionConfiguration,
                      transformer: @escaping (T) -> R) -> AsyncThrowingStream<R, Error> where T : Decodable, T : Encodable {
        return adaptor.stream(request: request, configuration: configuration, transformer: transformer)
    }
}
