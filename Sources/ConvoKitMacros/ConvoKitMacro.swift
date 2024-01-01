import SwiftCompilerPlugin
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

///
public struct ConvoAccessibleOld: MemberMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        UserDefaults.standard.set("abc", forKey: "abc")
        var generatedNotificationCenter = ""
        
        guard var classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw SkillIssueError()
        }
        
        let funcDecls = classDecl.memberBlock.members.map(\.decl)
        for decl in funcDecls {
            if var funcDecl = decl.as(FunctionDeclSyntax.self) {
                let nameOfFunction = funcDecl.name
                
                let listener = """
                NotificationCenter.default.addObserver(forName:  Notification.Name(rawValue: \"\(classDecl.name.trimmed)-\(nameOfFunction)\"), object: nil, queue: .main) { [weak self] _ in
                        self?.\(nameOfFunction)()
                }
                
                """
                generatedNotificationCenter.append(listener)
            }
        }
        return [DeclSyntax("""
        
        init() {
            self.initializeConvo()
        }
        
        public func initializeConvo() {
            \(raw: generatedNotificationCenter)
        }
        
        """)]
    }
}

public struct ConvoAccessible: MemberMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        
        var generatedFunctionsToCall = UserDefaults.standard.string(forKey: "generatedFunctionsToCall") ?? ""
        
        guard var classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw SkillIssueError()
        }
        
        let funcDecls = classDecl.memberBlock.members.map(\.decl)
        for decl in funcDecls {
            if var funcDecl = decl.as(FunctionDeclSyntax.self) {
                let nameOfFunction = funcDecl.name.text
                
                generatedFunctionsToCall.append(classDecl.name.text + ".shared." + nameOfFunction + "()\n")
            }
        }
        UserDefaults.standard.set(generatedFunctionsToCall, forKey: "generatedFunctionsToCall")

        return []
    }
}

public struct ConvoConnector: MemberMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        let generatedFunctionsToCall = UserDefaults.standard.string(forKey: "generatedFunctionsToCall") ?? ""
        let functionsSplit = generatedFunctionsToCall.split(separator: "\n")
        var codeToReturn = "func callFunctionIfNeeded() {"
        for function in functionsSplit {
            if let functionName = function.split(separator: ".").last {
                codeToReturn.append("""
        
            if messageLog == \"\(functionName)\" {
                \(function)
            }
        """
                )
            }
        }
        return [DeclSyntax(stringLiteral: codeToReturn + "\n}")]
    }
}

struct SkillIssueError: Error {
    
}
@main
struct ConvoKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ConvoAccessible.self,
        ConvoConnector.self
    ]
}
