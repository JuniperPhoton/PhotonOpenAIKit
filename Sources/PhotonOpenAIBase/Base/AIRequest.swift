//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/3/8.
//

import Foundation

public let openAIHost = "api.openai.com"

public enum AIRequestUrl: String {
    case chatCompletions = "/v1/chat/completions"
}

public protocol AIRequestBody: Codable {
    // empty
}

public protocol TextAIRequestBody: AIRequestBody {
    /// The model to use.
    /// Checkout built-in models in ``AIModel``.
    var model: String { get }
}

public protocol AIRequest {
    associatedtype Body: AIRequestBody
    
    var body: Body { get }
    var path: String { get }
    var method: AIRequestMethod { get }
    var streamMode: Bool { get }
}

public enum AIRequestMethod {
    case get
    case post
}
