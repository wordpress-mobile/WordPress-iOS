import Foundation
import Analyzer
import IndexStoreDB

func reportUnsafeCoreDataAPIUsages(indexStore: IndexStoreDB, compilerInvocations: CompilerInvocations) throws -> [Violation] {
    let symbolNavigator = SymbolNavigator(compilerInvocations: compilerInvocations, indexStore: indexStore)
    let sourceNavigator = SourceNavigator(compilerInvocations: compilerInvocations, indexStore: indexStore)

    let symbols = symbolNavigator.lookupCoreDataAPIs()
    var violations = [Violation]()
    for symbol in symbols {
        for callSite in sourceNavigator.callSites(of: USR(rawValue: symbol.usr)!) {
            print("\(symbol.name) is called at \(callSite)")

            let expression = try sourceNavigator.typecheck(location: callSite)
            let closure = try ASTHelper.parseFunctionParameterType(at: 1, function: expression)
            let returnType = try ASTHelper.parseFunctionReturnType(function: closure)

            let typeIdentifiers = ASTHelper.extractTypeIdentifier(returnType)
            let illegalTypes = try typeIdentifiers.reduce(into: [String]()) { partialResult, typename in
                if try symbolNavigator.isInheritence(subclass: typename, superclass: "NSManagedObject", usedAt: callSite) {
                    print("❌ \(typename) is a NSManagedObject")
                    partialResult.append(typename)
                }
            }

            if !illegalTypes.isEmpty {
                let newViolations = illegalTypes.map {
                    Violation(
                        message: "It's unsafe to return \($0) from \(symbol.name)",
                        file: URL(fileURLWithPath: callSite.path),
                        line: callSite.line,
                        column: callSite.utf8Column
                    )
                }
                violations.append(contentsOf: newViolations)
            }
        }
    }
    return violations
}
