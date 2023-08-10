import Foundation
import IndexStoreDB
import TSCBasic

extension IndexStoreDB {

    /// Create a `IndexStoreDB` instance using given data store.
    ///
    /// - Parameters:
    ///   - dataStorePath: Path to the data store directory. i.e. derived-data/Index.noindex/DataStore
    /// - Returns: Fully initialized `IndexStoreDB` instance.
    public static func from(dataStorePath: String) throws -> IndexStoreDB {
        print("Loading index store...")

        // The file is used by IndexStoreDB internally. It's okay to use a temporary directory.
        let databasePath = try AbsolutePath(validating: NSTemporaryDirectory()).appending(component: "static-analyzer-index-store.db").pathString

        let indexStore = try IndexStoreDB(
            storePath: dataStorePath,
            databasePath: databasePath,
            library: try IndexStoreLibrary(dylibPath: libIndexStorePath()),
            waitUntilDoneInitializing: true,
            listenToUnitEvents: false
        )

        print("Index store loaded from \(dataStorePath)")

        return indexStore
    }

    /// Find the libIndexStore.dylib bundled with current Swift toolchain.
    ///
    /// - Returns: Path to the libIndexStore.dylib file.
    static func libIndexStorePath() throws -> String {
        // This command returns the toolchain's bin path, i.e. /.../XcodeDefault.xctoolchain/usr/bin/swift
        let process = TSCBasic.Process(args: "/usr/bin/xcrun", "--find", "swift")
        try process.launch()
        let result = try process.waitUntilExit()
        let libPath = try AbsolutePath(validating: "../../lib/libIndexStore.dylib", relativeTo: AbsolutePath(validating: result.utf8Output()))
        return libPath.pathString
    }

}

extension Sequence {
    func removingDuplicates<Value: Hashable>(by keyPath: KeyPath<Element, Value>) -> [Element] {
        reduce(into: [Value: Element]()) { uniq, element in
            let key = element[keyPath: keyPath]
            uniq[key] = element
        }
        .values
        .map { $0 }
    }
}
