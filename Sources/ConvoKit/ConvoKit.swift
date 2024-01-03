// The Swift Programming Language
// https://docs.swift.org/swift-book

import Observation

/// A macro that exposes functions of a class to ConvoKit
@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
@attached(member, names: arbitrary)
public macro ConvoAccessible() = #externalMacro(module: "ConvoKitMacros", type: "ConvoAccessible")

/// A macro that given a string functionName, calls the function with the name functionName
@freestanding(declaration)
public macro ConvoConnector() = #externalMacro(module: "ConvoKitMacros", type: "ConvoConnector")

/// A macro that outputs the exposed functions passed to ConvoKit
@freestanding(expression)
public macro GetConvoState() -> String = #externalMacro(module: "ConvoKitMacros", type: "GetConvoState")
