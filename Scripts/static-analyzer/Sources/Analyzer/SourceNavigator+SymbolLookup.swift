import Foundation
import IndexStoreDB
import TSCBasic

extension SourceNavigator {

    public func definition(ofUSR usr: USR) -> Symbol? {
        let definitions = indexStore.occurrences(ofUSR: usr.rawValue, roles: .definition)
        if definitions.count > 1 {
            print("WARNING: More than one definition found for \(usr)")
        }
        return definitions.first?.symbol
    }

    public func lookupSymbols(name: String, kind: IndexSymbolKind) -> [Symbol] {
        indexStore.canonicalOccurrences(ofName: name)
            .filter { $0.symbol.kind == kind }
            .map { $0.symbol }
    }

    public func lookupSymbols(name: String, kind: IndexSymbolKind? = nil, in file: AbsolutePath) -> [Symbol] {
        var symbols = indexStore.symbols(inFilePath: file.pathString)
            .filter { $0.name == name }

        if let kind {
            symbols.removeAll { $0.kind != kind }
        }

        return symbols
    }

    public func lookupInstanceMethods(named symbolName: String, of symbol: Symbol) -> [Symbol] {
        assert(symbol.kind.isTypeDefinition)

        let superclasses = superclasses(of: symbol)
        let conformedProtocols = conformedProtocols(of: symbol)
        let usrsToLookUp = Set(([symbol] + superclasses + conformedProtocols).map { $0.usr })

        return indexStore.canonicalOccurrences(ofName: symbolName)
            .filter { (occurrence: SymbolOccurrence) in
                guard occurrence.symbol.kind == .instanceMethod else {
                    return false
                }

                let parents = occurrence.relations.compactMap { $0.roles.contains(.childOf) ? $0.symbol : nil }
                assert(parents.count == 1)

                var parent = parents[0]
                if parent.kind.isTypeDefinition {
                    // Do nothing
                } else if parent.kind == .extension {
                    let extensions = indexStore.occurrences(relatedToUSR: parent.usr, roles: .extendedBy)
                    assert(extensions.count == 1)
                    parent = extensions[0].symbol
                } else {
                    assertionFailure("Unexpected \(parent)")
                    return false
                }

                assert(parent.kind.isTypeDefinition)
                return usrsToLookUp.contains(parent.usr)
            }
            .map { $0.symbol }
            .removingDuplicates(by: \.usr)
    }

    public func conformedProtocols(of symbol: Symbol) -> [Symbol] {
        var all = [String: Symbol]()
        conformedProtocols(of: symbol, all: &all)
        return Array(all.values)
    }

    public func conformedProtocols(of symbol: Symbol, all: inout [String: Symbol]) {
        guard let definition = definition(ofUSR: USR(rawValue: symbol.usr)!)?.usr else {
            return
        }

        let extensions = indexStore.occurrences(ofUSR: symbol.usr, roles: .extendedBy)
            .compactMap { occurrence in
                occurrence.relations.first { $0.roles.contains(.extendedBy) }?.symbol.usr
            }

        let protocols = ([definition] + extensions)
            .compactMap { usr in
                indexStore.occurrences(relatedToUSR: usr, roles: .baseOf).map(\.symbol)
            }
            .flatMap { $0 }
            .filter { $0.kind == .protocol }
        protocols.forEach { proto in
            guard all[proto.usr] == nil else {
                return
            }
            all[proto.usr] = proto
            conformedProtocols(of: proto, all: &all)
        }
    }

    public func superclasses(of symbol: Symbol) -> [Symbol] {
        var result = [Symbol]()

        var clazz = symbol
        while true {
            guard let found = superclass(of: clazz) else {
                break
            }

            result.append(found)
            clazz = found
        }

        return result
    }

}

extension SourceNavigator {

    func resolve(classNamed name: String) throws -> Symbol {
        try resolve(classNamed: name, original: name)
    }

    func resolve(classNamed name: String, original: String) throws -> Symbol {
        let parts = name.split(separator: ".")
        if parts.count > 1, let last = parts.last {
            return try resolve(classNamed: String(last), original: original)
        }

        let candidates = indexStore.canonicalOccurrences(ofName: name)
            .removingDuplicates(by: \.symbol.usr)
            .map(\.symbol)
            .filter { symbol in
                if symbol.kind != .class {
                    return false
                }

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

        let bases = indexStore.occurrences(relatedToUSR: symbol.usr, roles: .baseOf)
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

        let parents = indexStore.occurrences(ofUSR: symbol.usr, roles: .childOf)
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
