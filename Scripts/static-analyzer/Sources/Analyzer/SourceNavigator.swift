import Foundation
import IndexStoreDB
import TSCBasic
import SourceKittenFramework

private let appModuleName = "WordPress"

public class SourceNavigator {

    let compilerInvocations: CompilerInvocations
    let indexStore: IndexStoreDB

    public init(compilerInvocations: CompilerInvocations, indexStore: IndexStoreDB) {
        self.compilerInvocations = compilerInvocations
        self.indexStore = indexStore
    }

    public func callSites(of symbol: Symbol) -> [SymbolLocation] {
        callSites(of: USR(rawValue: symbol.usr)!)
    }

    public func callSites(of usr: USR) -> [SymbolLocation] {
        indexStore.occurrences(ofUSR: usr.rawValue, roles: .call)
            .map(\.location)
    }

    public func expressions(at location: SymbolLocation) throws -> [Expression] {
        let compilerArguments = compilerInvocations.compilerArguments(forFileAt: location.path)
        let targetByteOffset = try Int64(StringView(String(contentsOfFile: location.path)).byteOffset(forLine: Int64(location.line), bytePosition: Int64(location.utf8Column))!.value)

        let request = Request.expressionType(file: location.path, compilerArguments: compilerArguments)
        let response = try request.send()

        guard let expressionTypeList = response["key.expression_type_list"] as? [[String: SourceKitRepresentable]] else {
            throw SourceKitResponseError.unexpectedType(key: "key.expression_type_list")
        }

        return try expressionTypeList
            .map { try Expression(sourceKitExpressionTypeResponse: $0) }
            .filter { $0.byteRange.contains(targetByteOffset) }
            .sorted { $0.byteRange.count < $1.byteRange.count }
    }

    public func isInheritence(subclass subclassName: String, superclass superclassName: String, usedAt location: SymbolLocation? = nil) throws -> Bool {
        do {
            let subclass = try resolveType(named: subclassName)
            let superclass = try resolveType(named: superclassName)
            return superclasses(of: subclass).map { $0.usr }.contains(superclass.usr)
        } catch {
            print(error)
        }

        if let location {
            print("Try SourceKit")
            return try isInheritence(subclass: subclassName, superclass: superclassName, usedAt: location, compilerArguments: compilerInvocations.compilerArguments(forFileAt: location.path))
        }

        return false
    }

    private func isInheritence(subclass typename: String, moduleName: String? = nil, superclass: String, usedAt location : SymbolLocation, compilerArguments: [String]) throws -> Bool {
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

        let response = try Request.cursorInfo(file: tempFile.path, offset: typenameOffset, arguments: newArgs).send()
        try response.ensureSourceKitSuccessfulReponse()

        let kind: String = try response.get("key.kind")
        guard kind == "source.lang.swift.ref.class" else {
            print("\(typename) is \(kind)")
            return false
        }

        let decl: String = try response.get("key.fully_annotated_decl")
        let regex = /<ref\.class.*>(.+)<\/ref.class>/
        guard let group = try regex.firstMatch(in: decl)?.1 else {
            throw AnyError(message: "Can't parse superclass name from declaration: \(decl)")
        }

        let superTypename = String(group)
        switch superTypename {
        case superclass: return true
        case "NSObject": return false
        case "MainActor": return false
        default:
            let moduleName: String = try response.get("key.modulename")
            return try isInheritence(subclass: superTypename, moduleName: moduleName, superclass: superclass, usedAt: location, compilerArguments: compilerArguments)
        }
    }

}

private extension String {
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

private extension IndexStoreDB {



}

extension IndexSymbolKind {
    var isTypeDefinition: Bool {
        switch self {
        case .enum, .struct, .class, .protocol:
            return true
        default:
            return false
        }
    }
}
