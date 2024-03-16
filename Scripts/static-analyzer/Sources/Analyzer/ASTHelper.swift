import Foundation
import SwiftSyntax
import SwiftParser

public enum ASTHelper {

    /// Parse a "Function Type" expression and return its parameter and return type.
    ///
    /// - SeeAlso: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/types#Function-Type
    /// - Parameter expression: The function's type expression.
    /// - Returns: The function's parameter and return type.
    public static func parseFunctionType(_ expression: String) throws -> (parameterType: [String], returnType: String) {
        let visitor = FunctionTypeVisitor(viewMode: .sourceAccurate)
        visitor.walk(Parser.parse(source: "let f: " + expression))

        guard let parameter = visitor.parameter else {
            throw AnyError(message: "Can't parse arguments from function expression: \(expression)")
        }
        guard let returnType = visitor.returnType else {
            throw AnyError(message: "Can't parse return type from function expression: \(expression)")
        }

        return (
            parameter.map { $0.withTrailingComma(nil).description },
            returnType.description
        )
    }

    /// Parse the type of a function's argument at given index.
    ///
    /// - SeeAlso: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/types#Function-Type
    /// - Parameters:
    ///   - position: The function argument's position, starting from 0.
    ///   - function: The function's type expression.
    /// - Returns: The return type.
    public static func parseFunctionParameterType(at position: UInt, function: String) throws -> String {
        // There are two possible function expression format:
        // 1. (Arg1, Arg2, Arg3) -> ReturnType
        // 2. (Arg1) -> (Arg2) -> (Arg3) -> ReturnType
        // The first one typically represents a global function, whereas the second one typically represents a instance method

        let (parameters, returnType) = try parseFunctionType(function)
        if parameters.count > 1 {
            // Parse the first format
            if position < parameters.count {
                return parameters[Int(position)]
            } else {
                throw AnyError(message: "Can't find argument at \(position) in \(function)")
            }
        } else {
            // Parse the second format
            if position > 0 {
                return try parseFunctionParameterType(at: position - 1, function: returnType)
            } else {
                return parameters[0]
            }
        }
    }

    /// Parse the return type of given function.
    ///
    /// - SeeAlso: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/types#Function-Type
    /// - Parameter function: The function's type expression.
    /// - Returns: The function's return type
    public static func parseFunctionReturnType(function: String) throws -> String {
        try parseFunctionType(function).returnType
    }

    public static func extractTypeIdentifier(_ declaration: String) -> [String] {
        let visitor = TypeIdentifiersVisitor(viewMode: .sourceAccurate)
        visitor.walk(Parser.parse(source: "let foo: \(declaration)"))

        if declaration.hasPrefix("Result<") {
            print("Got a result type")
        }

        // FIXME: Don't check all types that appeared in the 'resolvedTypename'
        // Only check T, T?, and Result<T, Error>.
        var identifiers = visitor.typeIdentifiers

        if identifiers.last == "Result", identifiers.count == 3 {
            identifiers.removeLast()
            identifiers.removeLast()
        }

        return identifiers
    }

}

private class FunctionTypeVisitor: SyntaxVisitor {
    var parameter: TupleTypeElementListSyntax?
    var returnType: TypeSyntax?

    override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
        parameter = node.arguments
        returnType = node.returnType
        return .skipChildren
    }
}

private class TypeIdentifiersVisitor: SyntaxVisitor {
    var typeIdentifiers = [String]()

    override func visitPost(_ node: SimpleTypeIdentifierSyntax) {
        typeIdentifiers.append(node.name.text)
    }

    override func visit(_ node: MemberTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
        typeIdentifiers.append(String(data: Data(node.syntaxTextBytes), encoding: .utf8)!)
        return .skipChildren
    }
}
