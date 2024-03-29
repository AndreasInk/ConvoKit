# ConvoKit

![ConvoKit Header.png](https://res.craft.do/user/full/23a03a79-af5e-1af9-b4ff-27170389b6b1/doc/E4042505-40C7-4BEF-BDD8-996CDFCB3A26/9F30F50D-72CB-4681-9921-5F119ECA1487_2/jsZakDIfy07L60tAEq8OobyWx7Hj8BzpzFukuxDzch0z/ConvoKit%20Header.png)

### Goal:

Make SwiftUI apps more accessible + powerful with conversation

### Why:

ConvoKit makes apps easier to use for everyone, but especially for people with disabilities.

### Idea:

Use Whisper to transcribe spoken natural language requests and tiny LLMs to understand the context behind the request to decide which swift function to call.

The development experience is as simple as adding a macro to the classes with at least one public function that you'd like to expose to the LLM and initializing the framework within your SwiftUI View.

### Setup:

```swift
@Observable
// Exposes all public functions to ConvoKit
@ConvoAccessible
class ContentViewModel {
        
    var navigationPath = NavigationPath()
    
    public func navigateToHome() {
        navigationPath.append(ViewType.home)
    }
    // Public functions are exposed to ConvoKit
    public func printNumber(number: Int) {
        print(number)
    }
}
```

```swift
// Initializes a view model that can interpret natural language through voice and speak back if you have a backend endpoint
@StateObject var streamer = ConvoStreamer(baseThinkURL: "", baseSpeakURL: "", 
                                          localWhisperURL:  Bundle.main.url(forResource: "ggml-tiny.en", withExtension: "bin")!)

func request(text: String) async {
    // A string that holds all options (the functions you marked as public)
    let options = #GetConvoState
    // LLM decides which function to call here
    if let function = await streamer.llmManager.chooseFunction(text: text, options: options) {
        callFunctionIfNeeded(functionName: function.functionName, args: function.args)
    }
}
    
func callFunctionIfNeeded(functionName: String, args: [String]) {
    // A macro that injects a bunch of if statements to handle the called function
    #ConvoConnector
}
```

### Basic Input + Output:

![ConvoKit Example.png](https://res.craft.do/user/full/23a03a79-af5e-1af9-b4ff-27170389b6b1/doc/E4042505-40C7-4BEF-BDD8-996CDFCB3A26/1C393D7F-396D-4065-9DF8-7CA5097F6EB9_2/iDQEW82ZAxggbGq0xLhyZwddoF4kreTMY77oLyRqAt8z/ConvoKit%20Example.png)

### Future Use Cases (ConvoKit isn't at this complexity yet, but this is the vision for it):

YouTube

1. Open YouTube, say "Find a video that is a SQL databases college level course"
2. YouTube finds a video based on your spoken words and plays it

Apple Health

1. Open Apple Health, say "How was my walking this week compared to last week?"
2. Apple health responds with, "Your overall mobility has declined but your step count is up!"
3. It then shows graphs explaining this data

### Live Simple Example:

https://github.com/AndreasInk/ConvoKit/assets/67549402/3f5dc956-8a2c-449f-b11b-5dabdf7508a4
