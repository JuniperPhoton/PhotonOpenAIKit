//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/3/8.
//

import Foundation
import PhotonOpenAIBase

/// Entry point to perform a chat completion request.
///
/// You use ``streamChatCompletion(request:)`` to get an ``AsyncThrowingStream`` with element of ``ChatCompletion/StreamResponse``.
/// You use ``streamChatCompletion(request:transformer:)`` to get an ``AsyncThrowingStream``,
/// and you can specify the transformer to convert ``ChatCompletion/StreamResponse`` to your data.
public class ChatCompletion {
    private let handler: RequestHandler
    
    init(handler: RequestHandler) {
        self.handler = handler
    }
    
    /// Chat completion in stream mode.
    /// This method returns an AsyncSequence, representing as ``AsyncThrowingStream``.
    ///
    /// You try await the sequence to get the stream result of ``ChatCompletion/StreamResponse``.
    /// To transform the ``ChatCompletion/StreamResponse`` to your data, use ``streamChatCompletion(request:transformer:)``.
    ///
    /// Since it runs on the Swift Concurrency context, to cancel the request, you simply call ``task/cancel()`` and handle the error in the catch block.
    ///
    /// ```
    /// let stream = stream(request: request)
    /// do {
    ///   for try await result in stream {
    ///       // handle result
    ///   }
    /// } catch {
    ///   // handle error
    /// }
    /// ```
    ///
    /// - parameter request: a ``ChatCompletion/Request`` with stream mode of true.
    public func stream(request: ChatCompletion.Request) -> AsyncThrowingStream<ChatCompletion.StreamResponse, Error> {
        return handler.stream(request: request, configuration: handler.configuration, transformer: { $0 })
    }
    
    /// Like ``streamChatCompletion(request:)``, but you can transform the ``ChatCompletion/StreamResponse`` to your data.
    /// - parameter request: a ``ChatCompletion/Request`` with stream mode of true.
    /// - parameter transformer: transform the ``ChatCompletion/StreamResponse`` to your data
    public func stream<T>(request: ChatCompletion.Request,
                          transformer: @escaping (ChatCompletion.StreamResponse) -> T) -> AsyncThrowingStream<T, Error> {
        return handler.stream(request: request, configuration: handler.configuration,
                              transformer: transformer)
    }
    
    /// Send request and get the result of ``ChatCompletion/Response``.
    /// - parameter request: a ``ChatCompletion/Request`` with stream mode of false.
    public func request(request: ChatCompletion.Request) async throws -> ChatCompletion.Response {
        return try await handler.request(request: request, configuration: handler.configuration)
    }
}

/// Defines request and response structure. See more in https://platform.openai.com/docs/api-reference/chat/create
extension ChatCompletion {
    public struct Request: AIRequest {
        /// The request body of a chat completion request.
        /// You use ``init(model:messages:)`` or ``init(system:user:assistant:)`` to construct the body.
        ///
        /// You can change other parameters by simply setting the properties.
        /// A quick way to change parameters is using ``apply(block:)`` method.
        ///
        /// ```
        /// let body = ChatCompletion.Request.Body(user: "").apply { body in
        ///    body.stream = true
        /// }
        /// ```
        /// Note that the default values are the same as the ones in the documentation.
        public struct Body: TextAIRequestBody {
            enum CodingKeys: String, CodingKey {
                case model = "model"
                case messages = "messages"
                case stream = "stream"
                case temperature = "temperature"
                case topP = "top_p"
                case n = "n"
                case maxTokens = "max_tokens"
                case presencePenalty = "presence_penalty"
                case frequencyPenalty = "frequency_penalty"
                case logitBias = "logit_bias"
                case user = "user"
            }
            
            public let model: String
            public let messages: [Message]
        
            public var stream: Bool = true
            public var temperature: Double = 1.0
            public var topP: Double = 1.0
            public var n: Int = 1
            public var stop: [String] = []
            public var maxTokens: Int? = nil
            public var presencePenalty: Double = 0.0
            public var frequencyPenalty: Double = 0.0
            public var logitBias: String? = nil
            public var user: String? = nil
            
            /// Initialize with a model and some messages, with stream mode.
            /// - parameter model: an ``AIModel``, defaults to .gpt_3_5_turbo
            /// - parameter messages: some messages
            public init(model: AIModel = AIModel.gpt_3_5_turbo,
                        messages: [Message]) {
                self.init(modelName: model.name, messages: messages)
            }
            
            /// Initialize with a model and some messages, with stream mode.
            /// - parameter modelName: The name of model. Defaults to .gpt_3_5_turbo.
            /// - parameter messages: some messages
            public init(modelName: String = AIModel.gpt_3_5_turbo.name,
                        messages: [Message]) {
                self.model = modelName
                self.messages = messages
            }
            
            /// Convenience initializer.
            /// - parameter system: system role
            /// - parameter userMessage: user role
            /// - parameter assistant: assistant role
            public init(model: AIModel = .gpt_3_5_turbo,
                        userMessage: String,
                        systemMessage: String? = nil,
                        assistantMessage: String? = nil) {
                self.init(
                    modelName: model.name,
                    userMessage: userMessage,
                    systemMessage: systemMessage,
                    assistantMessage: assistantMessage
                )
            }
            
            /// Convenience initializer.
            /// - parameter system: system role
            /// - parameter userMessage: user role
            /// - parameter assistant: assistant role
            public init(modelName: String = AIModel.gpt_3_5_turbo.rawValue,
                        userMessage: String,
                        systemMessage: String? = nil,
                        assistantMessage: String? = nil) {
                var messages: [ChatCompletion.Request.Message] = [
                    .init(role: "user", content: userMessage),
                ]
                
                if let systemMessage = systemMessage {
                    // System message should be at first
                    messages.insert(.init(role: "system", content: systemMessage), at: 0)
                }
                
                if let assistantMessage = assistantMessage {
                    messages.append(.init(role: "assistant", content: assistantMessage))
                }
                
                self.init(modelName: modelName, messages: messages)
            }
            
            public func apply(block: (inout Self) -> Void) -> Self {
                var request = self
                block(&request)
                return request
            }
        }
        
        public struct Message: Codable {
            public let role: String
            public let content: String
            
            public init(role: String, content: String) {
                self.role = role
                self.content = content
            }
        }
        
        public let body: Body
        public let path: String = AIRequestUrl.chatCompletions.rawValue
        public let method: AIRequestMethod = .post
        
        public var streamMode: Bool {
            self.body.stream
        }
        
        /// Construct the request with ``Body``.
        public init(_ body: Body) {
            self.body = body
        }
    }
}

extension ChatCompletion {
    /// https://platform.openai.com/docs/api-reference/completions/create
    public struct Response: Codable {
        public let id: String
        public let object: String
        public let created: Int64
        public let model: String
        public let choices: [Choice]
        
        public struct Choice: Codable {
            enum CodingKeys: String, CodingKey {
                case index = "index"
                case message = "message"
                case finishReason = "finish_reason"
            }
            
            public let index: Int
            public let message: Message
            public let finishReason: String?
        }
    }
    
    public struct Usage: Codable {
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
        
        public let promptTokens: Int
        public let completionTokens: Int
        public let totalTokens: Int
    }
    
    public struct Message: Codable {
        public let role: String?
        public let content: String?
    }
}

extension ChatCompletion {
    /// https://platform.openai.com/docs/api-reference/completions/create
    public struct StreamResponse: Codable {
        public let id: String
        public let object: String
        public let created: Int64
        public let model: String
        public let choices: [DeltaChoice]
        
        public struct DeltaChoice: Codable {
            enum CodingKeys: String, CodingKey {
                case index = "index"
                case delta = "delta"
                case finishReason = "finish_reason"
            }
            
            public let index: Int
            public let delta: Message
            public let finishReason: String?
        }
        
        public struct Choice: Codable {
            public let index: Int
            public let message: [Message]
        }
    }
}
