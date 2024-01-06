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
            if var funcDecl = decl.as(FunctionDeclSyntax.self), "\(funcDecl)".contains("public") {
                
                var args = [ConvoArgs]()
                let nameOfFunction = funcDecl.name.text
                for params in funcDecl.signature.parameterClause.parameters {
                    let returnType = params.type.description
                    let paramName = params.firstName.text
                    args.append(ConvoArgs(name: paramName, value: "", type: returnType))
                }
                let convoFunction = ConvoFunction(functionName: classDecl.name.text + ".shared." + nameOfFunction, args: args)
                ConvoState.shared.generatedFunctionsToCall.insert(convoFunction)
            }
        }

        return [DeclSyntax(stringLiteral: "static let shared = " + classDecl.name.text + "()")]
    }
}

public struct ConvoConnector: DeclarationMacro {
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        let convoState = ConvoState.shared.generatedFunctionsToCall
        var stringToReturn = ""
        
        for function in convoState {
            var argsString = ""
            var argIndex = 0
            for arg in function.args {
                argsString.append("""
                guard args.indices.contains(\(argIndex)), let \(arg.name) = \(arg.type)(args[\(argIndex)]) else {
                    return
                }
                """)
                argIndex += 1
            }
            var functionString = function.functionName + "("
            for arg in function.args {
                functionString += arg.name + ": " + arg.name
            }
            functionString += ")"
            let a = String(function.functionName.split(separator: "(").first ?? "")
            stringToReturn.append("""

            if functionName.contains(\"\(a)\") {
                \(argsString)
                \(functionString)
            }

        
        """)
            
        }
        return [DeclSyntax(stringLiteral: stringToReturn)]
    }
}

struct GetConvoState: ExpressionMacro {
    static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
        let convoState = ConvoState.shared.generatedFunctionsToCall
        var stringToReturn = ""
        for function in convoState {
            var functionString = function.functionName + "("
            for arg in function.args {
                functionString += arg.name + ": " + arg.name
            }
            functionString += "), "
            
            stringToReturn.append(functionString)
            
        }
        return ExprSyntax(stringLiteral: "\"\(stringToReturn)\"")
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
    public init(generatedFunctionsToCall: Set<ConvoFunction> = []) {
        self.generatedFunctionsToCall = generatedFunctionsToCall
    }
    public static var shared = ConvoState()
    var generatedFunctionsToCall: Set<ConvoFunction> = []
}

public struct ConvoFunction: Hashable {
    public static func == (lhs: ConvoFunction, rhs: ConvoFunction) -> Bool {
        return lhs.functionName == rhs.functionName
    }
    
    var functionName: String
    var args: [ConvoArgs]
}
public struct ConvoArgs: Hashable {
    var name: String
    var value: String
    var type: String
}
