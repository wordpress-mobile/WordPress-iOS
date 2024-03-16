import Foundation
import IndexStoreDB

public extension SourceNavigator {

    func lookupCoreDataAPIs() throws -> [Symbol] {
        let coreDataStackSwift = try resolveType(named: "CoreDataStackSwift")
        let coreDataStack = try resolveType(named: "CoreDataStack")
        return lookupInstanceMethods(named: "performAndSave(_:completion:on:)", of: coreDataStackSwift)
            + lookupInstanceMethods(named: "performAndSave(_:)", of: coreDataStackSwift)
            + lookupInstanceMethods(named: "performQuery(_:)", of: coreDataStack)
    }

}
