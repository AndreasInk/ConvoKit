// The Swift Programming Language
// https://docs.swift.org/swift-book

import Observation

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
//@attached(member, names: named(_$observationRegistrar), named(access), named(withMutation))
//@attached(memberAttribute)
@attached(member, names: arbitrary)
public macro ConvoAccessible() = #externalMacro(module: "ConvoKitMacros", type: "ConvoAccessible")

@freestanding(declaration)
public macro ConvoConnector() = #externalMacro(module: "ConvoKitMacros", type: "ConvoConnector")


@freestanding(expression)
public macro GetConvoState() -> String = #externalMacro(module: "ConvoKitMacros", type: "GetConvoState")
