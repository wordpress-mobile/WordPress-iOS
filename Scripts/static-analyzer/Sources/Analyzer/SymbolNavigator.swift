import Foundation
import IndexStoreDB
import SourceKittenFramework

private let appModuleName = "WordPress"

public class SymbolNavigator {

    let compilerInvocations: CompilerInvocations
    let indexStore: IndexStoreDB

    public init(compilerInvocations: CompilerInvocations, indexStore: IndexStoreDB) {
        self.compilerInvocations = compilerInvocations
        self.indexStore = indexStore
    }

    public func isInheritence(subclass subclassName: String, superclass superclassName: String, usedAt location: SymbolLocation) throws -> Bool {
        do {
            let subclass = try indexStore.resolve(name: subclassName)
            let superclass = try indexStore.resolve(name: superclassName)
            return indexStore.is(subclass, kindOf: superclass)
        } catch {
            print(error)
        }

        print("Try SourceKit")
        return try isInheritence(subclass: subclassName, superclass: superclassName, usedAt: location, compilerArguments: compilerInvocations.compilerArguments(forFileAt: location.path))
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

    func resolve(name: String) throws -> Symbol {
        try resolve(name: name, original: name)
    }

    func resolve(name: String, original: String) throws -> Symbol {
        let parts = name.split(separator: ".")
        if parts.count > 1, let last = parts.last {
            return try resolve(name: String(last), original: original)
        }

        let candidates = canonicalOccurrences(ofName: name)
            .removingDuplicates(by: \.symbol.usr)
            .map(\.symbol)
            .filter { symbol in

                // Don't consider a C macro as a candidate.
                if symbol.usr.hasPrefix("c:@macro@") {
                    return false
                }

                return fullTypename(of: symbol) == original
            }

        guard candidates.count == 1 else {
            throw AnalyzerError.symbolResolution(name: name, candidates: candidates)
        }

        return candidates[0]
    }

    func superclass(of symbol: Symbol) -> Symbol? {
        guard symbol.kind == .class else {
            return nil
        }

        let bases = occurrences(relatedToUSR: symbol.usr, roles: .baseOf)
            .filter { $0.symbol.kind == .class }
            .removingDuplicates(by: \.symbol.usr)
        if bases.count > 1 {
            print("Warning: Found \(bases.count) superclass of \(symbol.name)")
            for clazz in bases {
                print("  - \(clazz.symbol.name) in \(clazz.location.path)")
            }
        }

        return bases.first?.symbol
    }

    func `is`(_ symbol: Symbol, kindOf base: Symbol) -> Bool {
        var clazz: Symbol? = symbol
        while true {
            guard let local = clazz else {
                return false
            }

            if local == base {
                return true
            }

            clazz = superclass(of: local)
        }
    }

    func fullTypename(of symbol: Symbol) -> String? {
        let allowed: Set<IndexSymbolKind> = [
            .enum,
            .struct,
            .class,
            .protocol,
            .extension,
            .typealias
        ]
        guard allowed.contains(symbol.kind) else {
            return nil
        }

        let parents = occurrences(ofUSR: symbol.usr, roles: .childOf)
            .map { $0.relations }
            .flatMap { $0 }
            .reduce(into: [Symbol]()) { partialResult, relation in
                if relation.roles.contains(.childOf) {
                    partialResult.append(relation.symbol)
                } else {
                    print("What is this?")
                }
            }

        if parents.count > 1 {
            print("❌")
        }

        if let parent = parents.first, let parentName = fullTypename(of: parent) {
            return parentName + "." + symbol.name
        }

        return symbol.name
    }

}
