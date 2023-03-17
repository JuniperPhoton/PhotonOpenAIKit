//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/3/8.
//

import Foundation

public enum AIRequestUrl: String {
    case chatCompletions = "https://api.openai.com/v1/chat/completions"
}

public protocol AIRequestBody: Codable {
    // empty
}

public protocol TextAIRequestBody: AIRequestBody {
    var model: AIModel { get }
}

public protocol AIRequest {
    associatedtype Body: AIRequestBody
    
    var body: Body { get }
    var url: String { get }
    var method: AIRequestMethod { get }
    var streamMode: Bool { get }
}

public enum AIRequestMethod {
    case get
    case post
}
