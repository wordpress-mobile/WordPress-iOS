import Foundation
import IndexStoreDB
import SourceKittenFramework
import SwiftParser
import SwiftSyntax
import System

private let appModuleName = "WordPress"
private let performQueryUSR = "s:So13CoreDataStackP9WordPressE12performQueryyqd__qd__So22NSManagedObjectContextCclF"

func analyzePerformQueryReturnType(indexStore: IndexStoreDB, compilerInvocations: [String: [[String]]]) async throws -> [Violation] {
    var violations = [Violation]()
    for occurence in indexStore.occurrences(ofUSR: performQueryUSR, roles: .call) {
        let location = occurence.location
        let problematicReturnType = try await analyze(
            location: location,
            compilerArguments: compilerInvocations[location.path, default: [[]]].first ?? []
        )
        if let problematicReturnType {
            violations.append(Violation(message: "It's unsafe to return \(problematicReturnType) from performQuery", file: URL(fileURLWithPath: location.path), line: location.line, column: location.utf8Column))
        }
    }
    return violations
}

private func analyze(location: SymbolLocation, compilerArguments: [String]) async throws -> String? {
    print("performQuery is called at \(location)")

    let resolvedTypename = try await extractCandidateFromPerformQuery(location: location, compilerArguments: compilerArguments)
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
        if try await isManagedObject(typename: typename, usedIn: FilePath(location.path), compilerArguments: compilerArguments) {
            return resolvedTypename
        }
    }

    return nil
}

private func extractCandidateFromPerformQuery(location: SymbolLocation, compilerArguments: [String]) async throws -> String {
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

private func isManagedObject(typename: String, moduleName: String? = nil, usedIn file: FilePath, compilerArguments: [String]) async throws -> Bool {
    let fileManager = FileManager.default
    let tempFile = fileManager.temporaryDirectory.appendingPathComponent("temp.swift")
    try? fileManager.removeItem(at: tempFile)
    try fileManager.copyItem(at: URL(filePath: file)!, to: tempFile)

    var newCode = [String]()
    if let moduleName, moduleName.starts(with: "_") == false, moduleName != appModuleName {
        newCode.append("import \(moduleName)")
    }
    let typeCheckLine = "func injected_function() { var object: \(typename)? = nil }"
    let typeColumn = typeCheckLine.range(of: typename)!.upperBound.utf16Offset(in: typeCheckLine)
    newCode.append(typeCheckLine)
    let fileHandle = try FileHandle(forUpdating: tempFile)
    try fileHandle.seekToEnd()
    try fileHandle.write(contentsOf: newCode.joined(separator: "\n").data(using: .utf8)!)
    try fileHandle.close()

    var totalLines: Int64 = 0
    try String(contentsOf: tempFile).enumerateLines { line, _ in
        totalLines += 1
    }

    let newArgs = compilerArguments.map({ arg in
        if arg == file.string {
            return tempFile.path
        } else {
            return arg
        }
    })

    let offset = try StringView(String(contentsOf: tempFile)).byteOffset(forLine: totalLines, bytePosition: Int64(typeColumn))!

    let response = try await Request.cursorInfo(file: tempFile.path, offset: offset, arguments: newArgs).asyncSend()
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
        return try await isManagedObject(typename: superTypename, moduleName: moduleName, usedIn: file, compilerArguments: compilerArguments)
    }
}


private class SuperclassXMLParserDelegate: NSObject, XMLParserDelegate {
    var superTypename: String?

    var parsingRefClass = false

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        parsingRefClass = elementName == "ref.class"
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if parsingRefClass, superTypename == nil {
            superTypename = string
        }
    }
}
