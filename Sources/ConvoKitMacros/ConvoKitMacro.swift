import SwiftCompilerPlugin
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ConvoAccessible: MemberMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        
        
        guard var classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw SkillIssueError()
        }
        
        let funcDecls = classDecl.memberBlock.members.map(\.decl)
        for decl in funcDecls {
            if var funcDecl = decl.as(FunctionDeclSyntax.self) {
                let nameOfFunction = funcDecl.name.text
                
                ConvoState.shared.generatedFunctionsToCall.append(classDecl.name.text + ".shared." + nameOfFunction + "()\n")
            }
        }

        return [DeclSyntax(stringLiteral: "func test() {}")]
    }
}

public struct ConvoConnector: DeclarationMacro {
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        var codeToReturn = ""
        for function in ConvoState.shared.generatedFunctionsToCall.split(separator: "\n") {
            if let functionName = function.split(separator: ".").last {
                codeToReturn.append("""
        
            if functionName.contains(\"\(functionName)\") {
                \(function)
            }
        """
                )
            }
        }
        return [DeclSyntax(stringLiteral: codeToReturn)]
    }
}

struct GetConvoState: ExpressionMacro {
    static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
        let returns = ConvoState.shared.generatedFunctionsToCall.replacingOccurrences(of: "\n", with: " ")
        return ExprSyntax(stringLiteral: "\"\(returns)\"")
    }
}
struct SkillIssueError: Error {
    
}
@main
struct ConvoKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ConvoAccessible.self,
        ConvoConnector.self,
        GetConvoState.self
    ]
}

public struct ConvoState {
    public init(generatedFunctionsToCall: String = "") {
        self.generatedFunctionsToCall = generatedFunctionsToCall
    }
    public static var shared = ConvoState()
    var generatedFunctionsToCall = "" {
        willSet(newFunctions) {
            Array(Set(newFunctions.split(separator: "\n"))).joined(separator: "\n").replacingOccurrences(of: "\n", with: "")
        }
        didSet {
            
        }
    }
}
