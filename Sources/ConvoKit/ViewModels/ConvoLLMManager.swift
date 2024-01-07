//
//  ConvoLLMManager.swift
//
//
//  Created by Andreas Ink on 1/1/24.
//

import SwiftUI
import llama


public struct LLMResponse {
    public var functionName: String
    public var args: [String]
}
open class ConvoLLMManager {
    
    public init(messageLog: String = "", cacheCleared: Bool = false, llamaContext: LlamaContext? = nil, baseThinkURL: String) {
        self.messageLog = messageLog
        self.cacheCleared = cacheCleared
        self.llamaContext = llamaContext
        self.baseThinkURL = baseThinkURL
    }
   
    let baseThinkURL: String
    @Published public var messageLog = ""
    @Published public var lastFunction = ""
    @Published var cacheCleared = false
    let NS_PER_S = 1_000_000_000.0
    
    private var llamaContext: LlamaContext?
    private var defaultModelUrl: URL? {
        Bundle.main.url(forResource: "ggml-model", withExtension: "gguf", subdirectory: "models")
    }
    
    func setup() {
        
        do {
            try loadModel(modelUrl: defaultModelUrl)
        } catch {
            messageLog += "Error!\n"
        }
    }
    
    func loadModel(modelUrl: URL?) throws {
        if let modelUrl {
            messageLog += "Loading model...\n"
            llamaContext = try LlamaContext.create_context(path: modelUrl.path())

            messageLog += "Loaded model \(modelUrl.lastPathComponent)\n"
        } else {
            messageLog += "Load a model from the list below\n"
        }
    }

    @MainActor
    public func complete(prompt: String, text: String, options: String, isCompletingFunction: Bool) async -> String? {
        guard let llamaContext else {
            return ""
        }
        let length: Int = (prompt.count + text.count + options.count) / 2
        print("length: \(length)")
        let t_start = DispatchTime.now().uptimeNanoseconds
        await llamaContext.completion_init(text: prompt)
        let t_heat_end = DispatchTime.now().uptimeNanoseconds
        let t_heat = Double(t_heat_end - t_start) / NS_PER_S
        var correctOptionAppearCount = 0
        var results = ""
        while await llamaContext.n_cur < length {
            let result = await llamaContext.completion_loop()
            print(result)
            let newResult = results + result
            var delimiterString = "Correct"
            
            if newResult.contains(delimiterString) {
                //if options.split(separator: ", ").map({String($0)}).contains(root) {
                print("results: \(results)")
                await llamaContext.clear()
                return String(results.split(separator: delimiterString).first ?? "").replacingOccurrences(of: ":", with: "").replacingOccurrences(of: delimiterString, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            }
            results = newResult
            
        }
        
        let t_end = DispatchTime.now().uptimeNanoseconds
        let t_generation = Double(t_end - t_heat_end) / NS_PER_S
        let tokens_per_second = Double(await llamaContext.n_len) / t_generation
        
       // await llamaContext.clear()
        print(results)
        await clear()
        return results.replacingOccurrences(of: "\n", with: "")
        
    }
    
    @MainActor
    public func chooseFunction(text: String, options: String) async -> LLMResponse? {
        // Ensure the context is valid
        guard let llamaContext else {
            return nil
        }

        let cleanText = text.replacingOccurrences(of: "[BLANK_AUDIO]", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

        // Prompt to identify the most appropriate function
        let choosePrompt = """
        Determine the most suitable function call:
        Request Description: \(cleanText)
        Available Options: \(options)

        Correct Option:
        """

        // Attempt to identify the function name
        guard let functionName = await complete(prompt: choosePrompt, 
                                                text: cleanText, options: options, 
                                                isCompletingFunction: true)?.split(separator: ")").first else {
            return nil // Handle cases where the function name couldn't be determined
        }

        // If the function name doesn't contain "()", attempt to parse arguments
        var args: [String] = []
        if !functionName.contains("()") {
            let argumentsPrompt = """
            Determine the most suitable argument to pass to the function:
            Function Signature: ContentViewModel.shared.printNumber(number Int)
            Natural Language Input: Print the number 21

            Correct Argument Values:
            21
            
            Determine the most suitable argument to pass to the function:
            Function Signature: \(functionName)
            Natural Language Input: \(cleanText)

            Correct Argument Values:
            """



            // Attempt to parse the arguments
            if let argumentsString = await complete(prompt: argumentsPrompt,
                                                    text: cleanText,
                                                    options: options,
                                                    isCompletingFunction: false)?.split(separator: "\n\n").first {
                for arg in argumentsString.split(separator: ",").map({String($0)}) {
                    if let lastElement = arg.split(separator: ": ").last, let arg = lastElement.split(separator: "Correct Argument").first {
                        args.append(String(arg))
                    }
                }
            }

        }

        print("Function Name: \(functionName)")
        print("Arguments: \(args)")
        return LLMResponse(functionName: String(functionName), args: args)
    }


    func submitNewChat(_ text: String, chatInput: ChatInput = .emptyChat) async throws -> [ChatMessage] {
        
        var chatInput = chatInput
        chatInput.messages.append(ChatMessage(role: .user, content: text))
        
        var urlRequest = URLRequest(url: URL(string: baseThinkURL + "/generateChat")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let response = try await URLSession.shared.upload(for: urlRequest, from: try encoder.encode(chatInput))
        
        let data = response.0
        if let message = String(data: data, encoding: .utf8) {
            print(message)
            chatInput.messages.append(ChatMessage(role: .assistant, content: message))
    }
        return chatInput.messages
        
    }
    
    func clear() async {
        guard let llamaContext else {
            return
        }

        await llamaContext.clear()
        messageLog = ""
    }
}
