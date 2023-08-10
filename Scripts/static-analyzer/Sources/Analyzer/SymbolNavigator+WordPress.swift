import Foundation
import IndexStoreDB

public extension SourceNavigator {

    func lookupCoreDataAPIs() -> [Symbol] {
        let functions = [
            "performAndSave(_:completion:on:)",
            "performAndSave(_:)",
            "performQuery(_:)",
        ]
        let types = ["CoreDataStack", "CoreDataStackSwift"]

        return functions.map { name in
            indexStore.canonicalOccurrences(ofName: name)
                .filter { occurrence in
                    guard occurrence.symbol.kind == .instanceMethod else {
                        return false
                    }

                    let parent = occurrence.relations.first { $0.roles.contains(.childOf) }?.symbol.name
                    if let parent {
                        return types.contains(parent)
                    } else {
                        return false
                    }
                }
                .map { $0.symbol }
            }
            .flatMap { $0 }
    }

}
