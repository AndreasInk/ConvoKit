// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.



import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "ConvoKit",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ConvoKit",
            targets: ["ConvoKit"]
        ),
    ],
    dependencies: [
        // Depend on the Swift 5.9 release of SwiftSyntax
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
        .package(url: "https://github.com/ggerganov/llama.cpp.git", branch: "master")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "ConvoKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "llama", package: "llama.cpp")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "ConvoKit", dependencies: [
            .byName(name: "ConvoKitMacros"),
            .product(name: "llama", package: "llama.cpp")]),
     
        // A test target used to develop the macro implementation.
        .testTarget(
            name: "ConvoKitTests",
            dependencies: [
                "ConvoKitMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
