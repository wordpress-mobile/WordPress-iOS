import Foundation
import IndexStoreDB
import SourceKittenFramework
import SwiftParser
import SwiftSyntax
import System

private let appModuleName = "WordPress"

func analyzePerformQueryReturnType(indexStore: IndexStoreDB, compilerInvocations: [String: [[String]]]) async throws -> [Violation] {
    // These APIs all have a closure as their first argument, which is hard-coded in the analyzing code (the `extractCandidate` function specifically).
    let coreDataAPIUSRs = [
        // performQuery(_:)
        "s:So13CoreDataStackP9WordPressE12performQueryyqd__qd__So22NSManagedObjectContextCclF",
        // performAndSave(_:completion:on:)
        "s:9WordPress18CoreDataStackSwiftP14performAndSave_10completion2onyqd__So22NSManagedObjectContextCc_yqd__cSgSo17OS_dispatch_queueCtlF",
        // performAndSave(_:completion:on:) the throwing version
        "s:9WordPress18CoreDataStackSwiftP14performAndSave_10completion2onyqd__So22NSManagedObjectContextCKc_ys6ResultOyqd__s5Error_pGcSgSo17OS_dispatch_queueCtlF",
        // performAndSave(_:completion:on:) the async version
        "s:9WordPress18CoreDataStackSwiftP14performAndSaveyqd__qd__So22NSManagedObjectContextCKcYaKlF",
    ]

    var violations = [Violation]()
    for usr in coreDataAPIUSRs {
        for occurence in indexStore.occurrences(ofUSR: usr, roles: .call) {
            let location = occurence.location
            let problematicReturnType = try await analyze(
                location: location,
                compilerArguments: compilerInvocations[location.path, default: [[]]].first ?? []
            )
            if let problematicReturnType {
                violations.append(Violation(message: "It's unsafe to return \(problematicReturnType) from \(occurence.symbol.name)", file: URL(fileURLWithPath: location.path), line: location.line, column: location.utf8Column))
            }
        }
    }
    return violations
}

private func analyze(location: SymbolLocation, compilerArguments: [String]) async throws -> String? {
    print("performQuery is called at \(location)")

    let resolvedTypename = try await extractCandidate(location: location, compilerArguments: compilerArguments)
    print("Its return type is \(resolvedTypename)")

    let visitor = TypeIdentifierVisitor(viewMode: .sourceAccurate)
    visitor.walk(Parser.parse(source: "let object: \(resolvedTypename)"))

    // FIXME: Don't check all types that appeared in the 'resolvedTypename'
    // Only check T, T?, and Result<T, Error>.
    var typenames = visitor.typenames

    if typenames.first == "Result", typenames.count == 3 {
        typenames.removeFirst()
        typenames.removeLast()
    }

    for typename in typenames {
        if try await isManagedObject(typename: typename, usedAt: location, compilerArguments: compilerArguments) {
            print("❌ \(typename) is a NSManagedObject")
            return resolvedTypename
        }
    }

    return nil
}

private func extractCandidate(location: SymbolLocation, compilerArguments: [String]) async throws -> String {
    let expression = try await expressionType(location: location, compilerArguments: compilerArguments)
    let closure = try getFunctionArgumentType(at: 1, function: expression)
    return try getFunctionReturnType(function: closure)
}

private func getFunctionArgumentType(at index: Int, function: String) throws -> String {
    let (argument, returnType) = try parseFunctionType(expression: function)
    if index > 0 {
        return try getFunctionArgumentType(at: index - 1, function: returnType)
    } else {
        return argument
    }
}

private func getFunctionReturnType(function: String) throws -> String {
    try parseFunctionType(expression: function).returnType
}

private func expressionType(location: SymbolLocation, compilerArguments: [String]) async throws -> String {
    // https://github.com/apple/swift/blob/main/tools/SourceKit/docs/Protocol.md#expression-type
    let request = Request.customRequest(request: [
        "key.request": UID("source.request.expression.type"),
        "key.sourcefile": location.path,
        "key.compilerargs": compilerArguments,
        "key.expectedtypes": [String](),
    ])
    let response = try await request.asyncSend()
    let targetByteOffset = try StringView(String(contentsOfFile: location.path)).byteOffset(forLine: Int64(location.line), bytePosition: Int64(location.utf8Column))!

    guard let expressionTypeList = response["key.expression_type_list"] as? [[String: SourceKitRepresentable]] else {
        throw SourceKitResponseError.unexpectedType(key: "key.expression_type_list")
    }

    let found = try expressionTypeList.first { expression in
        guard let offset = expression["key.expression_offset"] else {
            throw SourceKitResponseError.missing(key: "key.expression_offset")
        }
        guard let offsetValue = offset as? Int64 else {
            throw SourceKitResponseError.unexpectedType(key: "key.expression_offset")
        }

        return offsetValue == targetByteOffset.value
    }

    guard let found else {
        throw AnyError(message: "Can't find the expression at \(location)")
    }

    guard let type = found["key.expression_type"] else {
        throw SourceKitResponseError.missing(key: "key.expression_type")
    }

    return type as! String
}

extension Dictionary where Key == String, Value == SourceKitRepresentable {
    func toJSON() -> String {
        let data = try! JSONSerialization.data(withJSONObject: self)
        return String(data: data, encoding: .utf8)!
    }

    func get<T: SourceKitRepresentable>(_ key: String, as type: T.Type = T.self) throws -> T {
        guard let value = self[key] else {
            throw SourceKitResponseError.missing(key: key)
        }
        guard let casted = value as? T else {
            throw SourceKitResponseError.unexpectedType(key: key)
        }
        return casted
    }

    func ensureSourceKitSuccessfulReponse() throws {
        if self["key.internal_diagnostic"] != nil {
            throw AnyError(message: "SourceKit failure: \(toJSON())")
        }
    }
}

// https://docs.swift.org/swift-book/documentation/the-swift-programming-language/types#Function-Type
private func parseFunctionType(expression: String) throws -> (argumentType: String, returnType: String) {
    let visitor = FunctionTypeVisitor(viewMode: .sourceAccurate)
    visitor.walk(Parser.parse(source: "let f: " + expression))
    guard let arguments = visitor.arguments else {
        throw AnyError(message: "Can't parse arguments from function expression: \(expression)")
    }
    guard let returnType = visitor.returnType else {
        throw AnyError(message: "Can't parse return type from function expression: \(expression)")
    }

    return (
        arguments.description,
        returnType.description
    )
}

private class FunctionTypeVisitor: SyntaxVisitor {
    var arguments: TupleTypeElementListSyntax?
    var returnType: TypeSyntax?

    override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
        arguments = node.arguments
        returnType = node.returnType
        return .skipChildren
    }
}

private class TypeIdentifierVisitor: SyntaxVisitor {
    var typenames = [String]()

    override func visitPost(_ node: SimpleTypeIdentifierSyntax) {
        typenames.append(node.name.text)
    }

    override func visit(_ node: MemberTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
        typenames.append(String(data: Data(node.syntaxTextBytes), encoding: .utf8)!)
        return .skipChildren
    }
}

private func isManagedObject(typename: String, moduleName: String? = nil, usedAt location : SymbolLocation, compilerArguments: [String]) async throws -> Bool {
    let fileManager = FileManager.default
    let tempFile = fileManager.temporaryDirectory.appendingPathComponent("temp.swift")
    var tempFileContent = try String(contentsOfFile: location.path)

    if let moduleName, moduleName.starts(with: "_") == false, moduleName != appModuleName {
        tempFileContent = tempFileContent.inserting("import \(moduleName)", atLine: 1)
    }


    let typeCheckCode = "let __injected_variable: \(typename)? = nil"
    let typenameLine = location.line + 1
    let typenameColumn = typeCheckCode.range(of: typename)!.upperBound.utf16Offset(in: typeCheckCode)
    tempFileContent = tempFileContent.inserting(typeCheckCode, atLine: typenameLine)

    try tempFileContent.write(to: tempFile, atomically: true, encoding: .utf8)
    let typenameOffset = StringView(tempFileContent).byteOffset(forLine: Int64(typenameLine), bytePosition: Int64(typenameColumn))!

    let newArgs = compilerArguments.map({ arg in
        if arg == location.path {
            return tempFile.path
        } else {
            return arg
        }
    })

    let response = try await Request.cursorInfo(file: tempFile.path, offset: typenameOffset, arguments: newArgs).asyncSend()
    try response.ensureSourceKitSuccessfulReponse()

    let kind: String = try response.get("key.kind")
    guard kind == "source.lang.swift.ref.class" else {
        return false
    }

    let decl: String = try response.get("key.fully_annotated_decl")
    let regex = /<ref\.class.*>(.+)<\/ref.class>/
    guard let group = try regex.firstMatch(in: decl)?.1 else {
        throw AnyError(message: "Can't parse superclass name from declaration: \(decl)")
    }

    let superTypename = String(group)
    switch superTypename {
    case "NSObject": return false
    case "NSManagedObject": return true
    case "MainActor": return false
    default:
        let moduleName: String = try response.get("key.modulename")
        return try await isManagedObject(typename: superTypename, moduleName: moduleName, usedAt: location, compilerArguments: compilerArguments)
    }
}

extension String {
    func inserting(_ string: String, atLine line: Int) -> String {
        precondition(line > 0)

        var allLines = [String]()
        self.enumerateLines { line, _ in
            allLines.append(line)
        }
        allLines.insert(string, at: line - 1)
        return allLines.joined(separator: "\n")
    }
}
