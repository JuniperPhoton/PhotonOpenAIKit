# PhotonOpenAIKit

A wrapper of OpenAI API, writing in Swift, featuring:

> Support for [SSE(server-sent events)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events), backed by Swift Concurrency [AsyncSequence](https://developer.apple.com/documentation/swift/asyncsequence).

Currently, it supports `ChatCompletion` only. With `gpt-3.5-turbo` it is power enough to use in most cases.

> The macOS menu bar app `Photon AI Translator` is powered by this library. You can download it on Mac App Store.

# Install

It supports Swift Package Manager. You can simply add it in your `Package Dependencies`.

```
https://github.com/JuniperPhoton/PhotonOpenAIKit
```

# Usage

## Import module

```swift
import PhotonOpenAIKit
```

## Create the client

You construct the client with a `API Key` and a network adaptor and keep reference to the client. The following code shows how to use `Alamofire`, a popular network framework, as the adaptor.

Note that this framework contains a built-in adaptor implementation for `Alamofire`, and you can just import and use it, like the following code.

```swift
import PhotonOpenAIAlamofireAdaptor

let adaptor = AlamofireAdaptor()
let client = PhotonAIClient(apiKey: apiKey, withAdaptor: AlamofireAdaptor())
```

If you changed the API key, you just deinit the old instance and construct a new one. Any running tasks should be cancelled by yourself.

## Create the request body

A quick way to construct a chat completion request with user message:
```swift
let request = ChatCompletion.Request(.init(userMessage: "Your prompt here"))
```

To fully configure your request:

```swift
let messages: [ChatCompletion.Request.Message] = [
    .init(role: "system", content: "Your system message"),
    .init(role: "user", content: "Your user message")
]

let request = ChatCompletion.Request(.init(messages: messages).apply { body in
    body.temperature = 0.2
    // other configurations here
})
```

> See the comments of the initializer to know more.

## Send request

After constructing a `ChatCompletion.Request`, now you can send the request and await for the result. 

### SSE mode
The code below shows how to use SSE mode to get the messages.

```swift
let task = Task {
     let request = ChatCompletion.Request(.init(userMessage: userMessage))
     let stream = client.chatCompletion.stream(request: request) { response in
         response.choices.first?.delta.content ?? ""
     }
     do {
         for try await result in stream {
             self.text += result
         }
     } catch {
         print("error \(error)")
         self.errorMessage = String(describing: error)
     }
}
```

After getting the `AsyncThrowingStream`, you use await-for-loop to get the result. If the request failed or got cancelled by user, you handle the result in the catch block.

### Normal mode

To get the decoded response directly, you set the request's stream mode to false, and try-await the result:

```swift
let request = ChatCompletion.Request(.init(userMessage: prompt).apply(block: { body in
    body.temperature = 0.1
    body.stream = false
}))

do {
    let response = try await aiClient.chatCompletion.request(request: request)
    let resultMessage = response.choices.first?.message.content ?? ""
    
    // do with your resultMessage
} catch {
    print("error is \(error)")
}
```

### Cancellation

To cancel a request, since it's in Swift Concurrency context, you simply cancel the task:

```swift
// Cancel
task.cancel()
```

## Advance usage

### Use your favorite network framework

It's easy to switch to your favorite network framework, instead of using the built-in `Alamofire`.

You import the `PhotonOpenAIBase` module, and adopt the `NetworkAdaptor` protocol.

```swift
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
```

### Throttling in SwiftUI

You don't want the UI updates too fast, neither it's pretty or performance-friendly.

Normally you have your result in your view model:

```swift
// Your view model
@Published var text: String = ""
```

You can simply use SwiftUI's `onReceived` to control how to throttle the flow:

```swift
struct ThrottlingOutputTextView: View {
    let outputText: Published<String>.Publisher
    
    @State private var textToDisplay = ""
    
    var body: some View {
        Text(textToDisplay)
            .onReceive(outputText.throttle(for: 0.2, scheduler: DispatchQueue.main, latest: true)) { output in
                withAnimation {
                    self.textToDisplay = output
                }
            }
    }
}

// Use in other view:
ThrottlingOutputTextView(outputText: viewModel.$text)
```


# Full Example

Please feel free to check out the example in this repo: https://github.com/JuniperPhoton/PhotonOpenAIKit/tree/main/PhotonOpenAIKitSample

# MIT License

Copyright (c) 2023 JuniperPhoton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
