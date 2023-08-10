import Foundation
import IndexStoreDB
import SourceKittenFramework

public class SourceNavigator {

    let compilerInvocations: CompilerInvocations
    let indexStore: IndexStoreDB

    public init(compilerInvocations: CompilerInvocations, indexStore: IndexStoreDB) {
        self.compilerInvocations = compilerInvocations
        self.indexStore = indexStore
    }

    public func callSites(of usr: USR) -> [SymbolLocation] {
        indexStore.occurrences(ofUSR: usr.rawValue, roles: .call)
            .map(\.location)
    }

    public func typecheck(location: SymbolLocation) throws -> String {
        let compilerArguments = compilerInvocations.compilerArguments(forFileAt: location.path)
        let targetByteOffset = try StringView(String(contentsOfFile: location.path)).byteOffset(forLine: Int64(location.line), bytePosition: Int64(location.utf8Column))!

        let request = Request.expressionType(file: location.path, compilerArguments: compilerArguments)
        let response = try request.send()

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

        return try found.get("key.expression_type")
    }

}
