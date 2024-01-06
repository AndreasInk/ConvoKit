# ConvoKit

### Goal:

Make SwiftUI apps more accessible with natural language + voice control

My Dad has Parkinson's which can make it difficult to use touch screens, especially when his tremors are worse.

I've attempted to develop computer vision based control apps with eye tracking but we find these very inaccurate, this is where ConvoKit can hopefully help.

### Idea:

Use Whisper to transcribe spoken natural language requests and tiny LLMs to understand the context behind the request to decide which swift function to call.

The development experience is as simple as adding a macro to the classes you'd like to expose to the LLM and initializing the framework within your SwiftUI View.

### Setup:

```swift
@Observable
@ConvoAccessible
class ContentViewModel {
        
    var naigationPath = NavigationPath()
    
    public func navigateToHome() {
        navigationPath.append(ViewType.home)
    }
    
    public func printNumber(number: Int) {
        print(number)
    }
}
```

```swift
@StateObject var streamer = ConvoStreamer(baseThinkURL: "", baseSpeakURL: "", localWhisperURL:  Bundle.main.url(forResource: "ggml-tiny.en", withExtension: "bin")!)
...
func request(text: String) async {
    let options = #GetConvoState
    if let function = await streamer.llmManager.chooseFunction(text: text, options: options) {
        print(function)
        callFunctionIfNeeded(functionName: function.functionName, args: function.args)
    }
}
    
func callFunctionIfNeeded(functionName: String, args: [String]) {
    #ConvoConnector
}
```

### Input + Output:

![ConvoKit Example.png](https://res.craft.do/user/full/23a03a79-af5e-1af9-b4ff-27170389b6b1/doc/E4042505-40C7-4BEF-BDD8-996CDFCB3A26/1C393D7F-396D-4065-9DF8-7CA5097F6EB9_2/iDQEW82ZAxggbGq0xLhyZwddoF4kreTMY77oLyRqAt8z/ConvoKit%20Example.png)

