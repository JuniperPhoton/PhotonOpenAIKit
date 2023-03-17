//
//  ContentView.swift
//  PhotonOpenAIKitSample
//
//  Created by Photon Juniper on 2023/3/8.
//

import SwiftUI
import PhotonOpenAIKit
import PhotonOpenAIAlamofireAdaptor

class MainViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading = false
    
    private var client: PhotonAIClient? = nil
    private var task: Task<Void, Never>? = nil
    
    func configureClient(apiKey: String) {
        client = PhotonAIClient(apiKey: apiKey, withAdaptor: AlamofireAdaptor())
    }
    
    func cancel() {
        task?.cancel()
    }
    
    @MainActor
    func request(userMessage: String) {
        cancel()
        task = Task {
            if userMessage.isEmpty {
                return
            }
            
            guard let client = client else {
                errorMessage = "Please configure with API Key"
                return
            }
                        
            withAnimation {
                self.isLoading = true
            }
            
            defer {
                withAnimation {
                    self.isLoading = false
                }
            }
            
            self.text = ""
            
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
    }
}

struct ContentView: View {
    @StateObject var viewModel = MainViewModel()
    
    @AppStorage("ApiKey")
    private var apiKey = ""
    
    @State var textToDisplay = ""
    @State var prompt = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                
                Button("Config API Key") {
                    if !apiKey.isEmpty {
                        viewModel.configureClient(apiKey: apiKey)
                    }
                }
            }
            
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
            }
            
            ScrollView {
                Text(textToDisplay).textSelection(.enabled)
                    .contentTransition(.interpolate)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .transition(.scale)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            HStack(spacing: 12) {
                TextField("Prompt", text: $prompt)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        viewModel.request(userMessage: prompt)
                    }
                    .disabled(viewModel.isLoading)
                
                if viewModel.isLoading {
                    ProgressView().controlSize(.small)
                }
                
                Button(viewModel.isLoading ? "Cancel ⌘R" : "Go ⌘R") {
                    if viewModel.isLoading {
                        viewModel.cancel()
                    } else {
                        viewModel.request(userMessage: prompt)
                    }
                }.buttonStyle(.borderedProminent).keyboardShortcut("r")
            }
        }
        .padding()
        .onReceive(viewModel.$text.throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)) { output in
            withAnimation {
                self.textToDisplay = output
            }
        }
        .onAppear {
            if !apiKey.isEmpty {
                viewModel.configureClient(apiKey: apiKey)
            }
        }
    }
}
