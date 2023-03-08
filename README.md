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

## Construct the client

You construct the client with a `API Key` and keep reference to the client:

```swift
let client = PhotonAIClient(apiKey: apiKey)
```

## Create your request body

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

## Send Request

After constructing a `ChatCompletion.Request`, now you can send the request and await for the result. The code below shows how to use SSE to get the messages.

```swift
let task = Task {
     let request = ChatCompletion.Request(.init(userMessage: userMessage))
     let stream = client.chatCompletion.streamChatCompletion(request: request) { response in
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

To cancel a request while stream, since it's in Swift Concurrency context, you simply cancel the task:

```swift
let task = Task {
    // 
}

// Cancel
task.cancel()
```

## Throttling in SwiftUI

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


# Example

Please feel free to check out the example in this repo.