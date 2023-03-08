//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/3/8.
//

import Foundation
import Alamofire

enum AIRequestUrl: String {
    case chatCompletions = "https://api.openai.com/v1/chat/completions"
}

protocol AIRequestBody: Codable {
    // empty
}

protocol TextAIRequestBody: AIRequestBody {
    var model: AIModel { get }
}

protocol AIRequest {
    associatedtype Body: AIRequestBody
    
    var body: Body { get }
    var url: String { get }
    var method: AIRequestMethod { get }
    var streamMode: Bool { get }
}

enum AIRequestMethod {
    case get
    case post
}

extension AIRequest {
    func getAlamofireMethod() -> Alamofire.HTTPMethod {
        switch self.method {
        case .post:
            return .post
        default:
            return .get
        }
    }
}
