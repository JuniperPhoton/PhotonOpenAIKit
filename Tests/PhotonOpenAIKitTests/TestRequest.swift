//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/4/22.
//

import Foundation
import XCTest
import PhotonOpenAIBase
import PhotonOpenAIKit
import PhotonOpenAIAlamofireAdaptor

class TestRequest: XCTestCase {
    func testAIRequest1() {
        testAIRequestInternal(body: createBodyWithSpecifiedParameters())
    }
    
    func testAIRequest2() {
        testAIRequestInternal(body: createBodyWithConvenientParameters())
    }
    
    private func testAIRequestInternal(body: ChatCompletion.Request.Body) {
        var body = body
        var request = ChatCompletion.Request(body)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.path, AIRequestUrl.chatCompletions.rawValue)
        XCTAssertEqual(request.streamMode, true)
        
        body.stream = false
        request = ChatCompletion.Request(body)
        XCTAssertEqual(request.streamMode, false)
        
        let messagesToVerified = request.body.messages.map { message in
            (message.role, message.content)
        }
        
        let messages = [("system", "system"), ("user", "user"), ("assistant", "assistant")]
        messages.forEach { (role, content) in
            let containsSystemMessage = messagesToVerified.contains { (r, c) in
                r == role && c == content
            }
            XCTAssert(containsSystemMessage)
        }
        
        testBody(body: body)
    }
    
    private func testBody(body: ChatCompletion.Request.Body) {
        var body = body
        XCTAssertEqual(body.frequencyPenalty, 0.0)
        XCTAssertEqual(body.logitBias, nil)
        XCTAssertEqual(body.user, nil)
        XCTAssertEqual(body.presencePenalty, 0.0)
        XCTAssertEqual(body.stop.count, 0)
        XCTAssertEqual(body.n, 1)
        XCTAssertEqual(body.topP, 1.0)
        XCTAssertEqual(body.temperature, 1.0)
        
        body.frequencyPenalty = 2.0
        body.logitBias = "bias"
        body.user = "user"
        body.presencePenalty = 1.0
        body.stop.append("stop")
        body.n = 2
        body.topP = 2.0
        body.temperature = 2.0
        
        XCTAssertEqual(body.frequencyPenalty, 2.0)
        XCTAssertEqual(body.logitBias, "bias")
        XCTAssertEqual(body.user, "user")
        XCTAssertEqual(body.presencePenalty, 1.0)
        XCTAssertEqual(body.stop.count, 1)
        XCTAssertEqual(body.n, 2)
        XCTAssertEqual(body.topP, 2.0)
        XCTAssertEqual(body.temperature, 2.0)
    }
    
    private func createBodyWithSpecifiedParameters() -> ChatCompletion.Request.Body {
        return ChatCompletion.Request.Body(userMessage: "user",
                                           systemMessage: "system",
                                           assistantMessage: "assistant")
    }
    
    private func createBodyWithConvenientParameters() -> ChatCompletion.Request.Body {
        return ChatCompletion.Request.Body(messages: [.init(role: "system", content: "system"),
                                                      .init(role: "user", content: "user"),
                                                      .init(role: "assistant", content: "assistant")])
    }
}
